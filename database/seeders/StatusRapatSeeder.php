<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class StatusRapatSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('status_rapat')->insert([
            ['id_status' => 1, 'status_rapat' => 'Diterima', 'desc' => 'Rapat telah diterima dan dijadwalkan.'],
            ['id_status' => 2, 'status_rapat' => 'Ditolak', 'desc' => 'Rapat telah ditolak.'],
            ['id_status' => 3, 'status_rapat' => 'Menunggu', 'desc' => 'Rapat sedang menunggu konfirmasi.'],
        ]);
    }
}
