<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Role extends Model
{
    use HasFactory;

    protected $table = 'role';
    protected $primaryKey = 'id_role';

    protected $fillable = [
        'role', // PERBAIKAN: Seharusnya 'role', bukan 'name'
    ];

    // PERBAIKAN: Tambahkan accessor untuk mendapatkan nama role
    public function getNameAttribute()
    {
        return $this->role;
    }

    /**
     * Mendefinisikan relasi "hasMany" ke model User.
     */
    public function users()
    {
        return $this->hasMany(User::class, 'id_role', 'id_role');
    }
}