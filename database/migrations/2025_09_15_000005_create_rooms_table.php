<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateRoomsTable extends Migration
{
    public function up()
    {
        Schema::create('room', function (Blueprint $table) {
            $table->id("id_room");
            $table->string('room', 100);
            $table->unsignedBigInteger('id_cabang');

            // Foreign Key
            $table->foreign('id_cabang')->references('id')->on('cabang')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('rooms');
    }
}