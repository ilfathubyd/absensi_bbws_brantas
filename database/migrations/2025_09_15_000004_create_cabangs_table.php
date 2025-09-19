<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCabangsTable extends Migration
{
    public function up()
    {
        Schema::create('cabang', function (Blueprint $table) {
            $table->id();
            $table->string('cabang', 100);
            $table->string('alamat', 100)->nullable();
        });
    }

    public function down()
    {
        Schema::dropIfExists('cabangs');
    }
}