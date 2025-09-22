<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class StatusRapatSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('status_rapat')->insert([
            ['id' => 1, 'status_rapat' => 'Diterima', 'desc' => 'Rapat telah diterima dan dijadwalkan.'],
            ['id' => 2, 'status_rapat' => 'Ditolak', 'desc' => 'Rapat telah ditolak.'],
            ['id' => 3, 'status_rapat' => 'Menunggu', 'desc' => 'Rapat sedang menunggu konfirmasi.'],
        ]);
    }
}
