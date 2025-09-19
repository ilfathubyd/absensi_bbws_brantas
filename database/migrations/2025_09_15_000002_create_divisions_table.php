<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDivisionsTable extends Migration
{
    public function up()
    {
        Schema::create('division', function (Blueprint $table) {
            $table->increments('id_division'); // INT UNSIGNED
            $table->string('division_name', 100);
        });
    }

    public function down()
    {
        Schema::dropIfExists('divisions');
    }
}
