<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cabang extends Model
{
    use HasFactory;

    protected $table = 'cabang';
    protected $primaryKey = 'id';

    protected $fillable = [
        'cabang',
        'alamat',
    ];

    /**
     * Mendefinisikan relasi "hasMany" ke model Room.
     */
    public function room()
    {
        return $this->hasMany(Room::class, 'id_cabang', 'id');
    }

    /**
     * Mendefinisikan relasi "hasMany" ke model Rapat.
     */
    public function rapat()
    {
        return $this->hasMany(Rapat::class, 'id_room', 'id_cabang');
    }
}