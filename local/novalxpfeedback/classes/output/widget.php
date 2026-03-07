<?php

namespace local_novalxpfeedback\output;

use renderable;
use renderer_base;
use templatable;

defined('MOODLE_INTERNAL') || die();

class widget implements renderable, templatable {
    public function export_for_template(renderer_base $output): array {
        return [
            'title' => false,
            'inputlabel' => get_string('widgettitle', 'local_novalxpfeedback'),
            'placeholder' => get_string('widgetplaceholder', 'local_novalxpfeedback'),
            'submitlabel' => get_string('widgetsubmit', 'local_novalxpfeedback'),
            'emptyerror' => get_string('widgetempty', 'local_novalxpfeedback'),
        ];
    }
}
