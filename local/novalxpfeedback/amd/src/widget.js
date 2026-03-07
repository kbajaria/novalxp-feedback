define(['core/ajax', 'core/notification'], function(Ajax, Notification) {
    const SELECTOR = '.js-novalxpfeedback';

    const setStatus = (root, message, isError) => {
        const status = root.querySelector('.novalxp-feedback-widget__status');
        status.textContent = message;
        status.dataset.state = isError ? 'error' : 'success';
    };

    const setBusy = (root, busy) => {
        const input = root.querySelector('.novalxp-feedback-widget__input');
        const button = root.querySelector('.novalxp-feedback-widget__submit');
        input.disabled = busy;
        button.disabled = busy;
        root.dataset.busy = busy ? 'true' : 'false';
    };

    const normaliseError = (error) => {
        if (error && error.message) {
            return error.message;
        }
        return 'We could not send your feedback right now. Please try again.';
    };

    const submit = (root) => {
        const input = root.querySelector('.novalxp-feedback-widget__input');
        const feedback = input.value.trim();
        const emptyError = root.dataset.emptyError || 'Enter some feedback before sending.';

        if (!feedback) {
            setStatus(root, emptyError, true);
            input.focus();
            return;
        }

        setBusy(root, true);
        setStatus(root, '', false);

        Ajax.call([{
            methodname: 'local_novalxpfeedback_submit_feedback',
            args: {feedback: feedback}
        }])[0]
            .then((response) => {
                setStatus(root, response.message, !response.status);
                if (response.status) {
                    input.value = '';
                }
                setBusy(root, false);
                return null;
            })
            .catch((error) => {
                setBusy(root, false);
                setStatus(root, normaliseError(error), true);
                Notification.exception(error);
            });
    };

    const bind = (root) => {
        const input = root.querySelector('.novalxp-feedback-widget__input');
        const button = root.querySelector('.novalxp-feedback-widget__submit');

        if (!input || !button || root.dataset.initialised === 'true') {
            return;
        }

        button.addEventListener('click', function() {
            submit(root);
        });

        input.addEventListener('keydown', function(event) {
            if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
                event.preventDefault();
                submit(root);
            }
        });

        root.dataset.initialised = 'true';
    };

    return {
        init: function() {
            document.querySelectorAll(SELECTOR).forEach(bind);
        }
    };
});
