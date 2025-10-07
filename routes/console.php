<?php

use App\Console\Commands\UpdateRapatStatus;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Daftarkan jadwal di sini
Schedule::command(UpdateRapatStatus::class)->everyMinute();
