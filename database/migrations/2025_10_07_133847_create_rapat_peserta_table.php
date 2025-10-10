<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('rapat_peserta', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_rapat')->constrained('rapat', 'id_rapat')->onDelete('cascade');
            $table->foreignId('id_user')->constrained('users', 'id_user')->onDelete('cascade');
            $table->timestamps();

            $table->unique(['id_rapat', 'id_user']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rapat_peserta');
    }
};
