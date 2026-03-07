const requiredEnv = ['TRELLO_KEY', 'TRELLO_TOKEN', 'TRELLO_LIST_ID', 'ENDPOINT_TOKEN'];

const json = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(body)
});

const truncate = (value, length) => {
  if (!value) {
    return '';
  }
  return value.length > length ? value.slice(0, length) : value;
};

const buildCardName = (feedback, fullname) => {
  const summary = truncate(feedback.replace(/\s+/g, ' ').trim(), 60);
  return `Learner feedback: ${summary} (${fullname || 'Unknown user'})`;
};

const buildCardDescription = (payload) => {
  const lines = [
    'Submitted from NovaLXP front page.',
    '',
    'Feedback:',
    payload.feedback,
    '',
    'Learner details:',
    `- Name: ${payload.fullname || 'Unknown'}`,
    `- User ID: ${payload.userid ?? 'Unknown'}`,
    `- Username: ${payload.username || 'Unknown'}`,
    `- Email: ${payload.email || 'Not available'}`,
    `- Site: ${payload.siteurl || 'Unknown'}`,
    `- Submitted at: ${payload.submittedat || new Date().toISOString()}`,
  ];

  return lines.join('\n');
};

const validateEnv = () => {
  for (const name of requiredEnv) {
    if (!process.env[name]) {
      throw new Error(`Missing required environment variable: ${name}`);
    }
  }
};

const isHttpEvent = (event) => !!event?.requestContext || typeof event?.body !== 'undefined';

const parseBody = (event) => {
  if (!isHttpEvent(event)) {
    return event;
  }

  if (!event.body) {
    return null;
  }

  const body = event.isBase64Encoded
    ? Buffer.from(event.body, 'base64').toString('utf8')
    : event.body;

  return JSON.parse(body);
};

export const handler = async (event) => {
  try {
    validateEnv();

    if (isHttpEvent(event)) {
      const authHeader = event.headers?.authorization || event.headers?.Authorization || '';
      const expected = `Bearer ${process.env.ENDPOINT_TOKEN}`;
      if (authHeader !== expected) {
        return json(401, {status: false, message: 'Unauthorized'});
      }
    }

    const payload = parseBody(event);
    if (!payload || typeof payload.feedback !== 'string' || payload.feedback.trim() === '') {
      return isHttpEvent(event)
        ? json(400, {status: false, message: 'Missing feedback'})
        : {status: false, message: 'Missing feedback'};
    }

    const trelloResponse = await fetch('https://api.trello.com/1/cards', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        idList: process.env.TRELLO_LIST_ID,
        name: buildCardName(payload.feedback, payload.fullname),
        desc: buildCardDescription(payload),
        key: process.env.TRELLO_KEY,
        token: process.env.TRELLO_TOKEN,
        pos: 'bottom'
      })
    });

    const responseText = await trelloResponse.text();
    if (!trelloResponse.ok) {
      console.error('Trello card creation failed', trelloResponse.status, responseText);
      return isHttpEvent(event)
        ? json(502, {status: false, message: 'Trello request failed'})
        : {status: false, message: 'Trello request failed'};
    }

    const success = {
      status: true,
      message: 'Thanks. Your feedback has been sent.'
    };

    return isHttpEvent(event) ? json(200, success) : success;
  } catch (error) {
    console.error('Feedback lambda failed', error);
    return isHttpEvent(event)
      ? json(500, {status: false, message: 'Internal server error'})
      : {status: false, message: 'Internal server error'};
  }
};
