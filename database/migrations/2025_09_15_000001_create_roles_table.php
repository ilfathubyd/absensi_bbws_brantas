<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateRolesTable extends Migration
{
    public function up()
    {
        Schema::create('role', function (Blueprint $table) {
            $table->increments('id_role'); // INT UNSIGNED
            $table->string('role', 100);
        });
    }

    public function down()
    {
        Schema::dropIfExists('roles');
    }
}
