<?php

namespace local_novalxpfeedback\external;

use context_system;
use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;
use moodle_exception;

defined('MOODLE_INTERNAL') || die();

class submit_feedback extends external_api {
    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'feedback' => new external_value(PARAM_TEXT, 'Learner feedback text', VALUE_REQUIRED),
        ]);
    }

    public static function execute(string $feedback): array {
        global $CFG, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['feedback' => $feedback]);
        self::validate_context(context_system::instance());
        require_login();

        $feedback = trim($params['feedback']);
        if ($feedback === '') {
            throw new moodle_exception('widgetempty', 'local_novalxpfeedback');
        }

        $functionname = trim((string)get_config('local_novalxpfeedback', 'lambdafunctionname'));
        $region = trim((string)get_config('local_novalxpfeedback', 'lambdaregion'));
        if ($functionname === '' || $region === '') {
            throw new moodle_exception('widgeterror', 'local_novalxpfeedback');
        }

        $payload = [
            'feedback' => $feedback,
            'userid' => (int)$USER->id,
            'fullname' => fullname($USER),
            'email' => $USER->email ?? '',
            'username' => $USER->username ?? '',
            'siteurl' => $CFG->wwwroot,
            'submittedat' => gmdate('c'),
        ];

        [$statuscode, $responsebody, $stderr] = self::invoke_lambda($functionname, $region, $payload);
        if ($statuscode !== 0) {
            debugging('NovaLXP feedback Lambda invoke failed: ' . s($stderr), DEBUG_DEVELOPER);
            throw new moodle_exception('widgeterror', 'local_novalxpfeedback');
        }

        $decoded = json_decode($responsebody, true);
        if (!is_array($decoded) || empty($decoded['status'])) {
            debugging('NovaLXP feedback Lambda returned unexpected payload: ' . s($responsebody), DEBUG_DEVELOPER);
            throw new moodle_exception('widgeterror', 'local_novalxpfeedback');
        }

        return [
            'status' => true,
            'message' => !empty($decoded['message'])
                ? (string)$decoded['message']
                : get_string('widgetsuccess', 'local_novalxpfeedback'),
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'status' => new external_value(PARAM_BOOL, 'Whether the submission succeeded'),
            'message' => new external_value(PARAM_TEXT, 'User-facing status message'),
        ]);
    }

    private static function invoke_lambda(string $functionname, string $region, array $payload): array {
        $payloadfile = tempnam(sys_get_temp_dir(), 'novalxpfeedback_payload_');
        $outputfile = tempnam(sys_get_temp_dir(), 'novalxpfeedback_output_');
        if ($payloadfile === false || $outputfile === false) {
            throw new moodle_exception('widgeterror', 'local_novalxpfeedback');
        }

        file_put_contents($payloadfile, json_encode($payload));

        $command = [
            'aws',
            'lambda',
            'invoke',
            '--region',
            $region,
            '--function-name',
            $functionname,
            '--cli-binary-format',
            'raw-in-base64-out',
            '--cli-connect-timeout',
            '10',
            '--cli-read-timeout',
            '20',
            '--payload',
            'fileb://' . $payloadfile,
            $outputfile,
        ];

        $descriptor = [
            0 => ['pipe', 'r'],
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w'],
        ];

        $process = proc_open($command, $descriptor, $pipes);
        if (!is_resource($process)) {
            @unlink($payloadfile);
            @unlink($outputfile);
            throw new moodle_exception('widgeterror', 'local_novalxpfeedback');
        }

        fclose($pipes[0]);
        $stdout = stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        $stderr = stream_get_contents($pipes[2]);
        fclose($pipes[2]);
        $statuscode = proc_close($process);

        $responsebody = is_file($outputfile) ? (string)file_get_contents($outputfile) : '';
        @unlink($payloadfile);
        @unlink($outputfile);

        return [$statuscode, $responsebody, trim($stderr . "\n" . $stdout)];
    }
}
