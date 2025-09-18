<?php


use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateUsersTable extends Migration
{
    public function up()
    {
        Schema::create('users', function (Blueprint $table) {
            $table->bigIncrements('id'); // bigInteger() for user ID
            $table->unsignedInteger('id_role');
            $table->unsignedInteger('id_division');
            $table->string('username', 255)->unique();
            $table->string('name', 255);
            $table->string('email', 100)->unique();
            $table->string('phone', 100)->nullable();
            $table->enum('gender', ['male', 'female', 'other'])->nullable();
            $table->string('password', 255);
            $table->string('photo', 255)->nullable();
            $table->timestamps();

            // Foreign Keys
            $table->foreign('id_role')->references('id')->on('roles')->onDelete('cascade');
            $table->foreign('id_division')->references('id')->on('divisions')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('users');
    }
}
