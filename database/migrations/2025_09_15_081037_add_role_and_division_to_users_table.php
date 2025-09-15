<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
  public function up()
{
    Schema::table('users', function (Blueprint $table) {
        // Menambahkan foreign key untuk division
        $table->foreignId('id_division')->nullable()->constrained('division', 'id_division')->onDelete('set null');
        
        // Menambahkan foreign key untuk role
        $table->foreignId('id_role')->nullable()->constrained('role', 'id_role')->onDelete('set null');
    });
}

// Penting juga untuk mengisi method down() untuk rollback
public function down()
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropForeign(['id_division']);
        $table->dropForeign(['id_role']);
        $table->dropColumn(['id_division', 'id_role']);
    });
}
};
