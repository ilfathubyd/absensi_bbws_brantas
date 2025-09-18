<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateStatusRapatsTable extends Migration
{
    public function up()
    {
        Schema::create('status_rapats', function (Blueprint $table) {
            $table->id();
            $table->string('status_rapat', 100);
            $table->string('desc', 100)->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('status_rapats');
    }
}
