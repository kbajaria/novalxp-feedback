<?php

defined('MOODLE_INTERNAL') || die();

$functions = [
    'local_novalxpfeedback_submit_feedback' => [
        'classname' => 'local_novalxpfeedback\\external\\submit_feedback',
        'description' => 'Submit front-page learner feedback to Trello.',
        'type' => 'write',
        'ajax' => true,
        'loginrequired' => true,
    ],
];
