<?php

namespace local_novalxpfeedback\privacy;

use core_privacy\local\metadata\collection;
use core_privacy\local\metadata\provider as metadata_provider;

defined('MOODLE_INTERNAL') || die();

class provider implements metadata_provider {
    public static function get_metadata(collection $collection): collection {
        $collection->add_external_location_link('feedbackendpoint', [
            'fullname' => 'privacy:metadata:endpoint:fullname',
            'email' => 'privacy:metadata:endpoint:email',
            'userid' => 'privacy:metadata:endpoint:userid',
            'feedback' => 'privacy:metadata:endpoint:feedback',
            'siteurl' => 'privacy:metadata:endpoint:siteurl',
            'submittedat' => 'privacy:metadata:endpoint:submittedat',
        ], 'privacy:metadata:endpoint');

        return $collection;
    }
}
