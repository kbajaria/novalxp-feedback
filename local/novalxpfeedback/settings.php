<?php

defined('MOODLE_INTERNAL') || die();

if ($hassiteconfig) {
    $settings = new admin_settingpage('local_novalxpfeedback', get_string('settings', 'local_novalxpfeedback'));

    $settings->add(new admin_setting_configtext(
        'local_novalxpfeedback/lambdafunctionname',
        get_string('lambdafunctionname', 'local_novalxpfeedback'),
        get_string('lambdafunctionname_desc', 'local_novalxpfeedback'),
        'novalxp-feedback-dev',
        PARAM_ALPHANUMEXT
    ));

    $settings->add(new admin_setting_configtext(
        'local_novalxpfeedback/lambdaregion',
        get_string('lambdaregion', 'local_novalxpfeedback'),
        get_string('lambdaregion_desc', 'local_novalxpfeedback'),
        'eu-west-2',
        PARAM_ALPHANUMEXT
    ));

    $ADMIN->add('localplugins', $settings);
}
