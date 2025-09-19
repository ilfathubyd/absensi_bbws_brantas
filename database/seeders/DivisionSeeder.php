<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DivisionSeeder extends Seeder
{
    //
    //  BELUM FIX
    //
    public function run(): void
    {
        DB::table('division')->insert([
            ['id_division' => 2000, 'division_name' => 'Administrator'],
            ['id_division' => 2001, 'division_name' => 'Kepala Devisi'],
            ['id_division' => 2002, 'division_name' => 'Staff'],
        ]);
    }
}
