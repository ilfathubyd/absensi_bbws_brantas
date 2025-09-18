<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('role')->insert([
            ['id_role' => 1, 'role' => 'Admin'],
            ['id_role' => 2, 'role' => 'PIC'],
            ['id_role' => 3, 'role' => 'User'],
        ]);
    }
}
