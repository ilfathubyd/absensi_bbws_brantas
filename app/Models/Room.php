<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Room extends Model
{
    use HasFactory;

    protected $table = 'room';
    protected $primaryKey = 'id_room';

    protected $fillable = [
        'room',
        'id_cabang',
    ];

    /**
     * Mendefinisikan relasi "belongsTo" ke model Cabang.
     */
    public function cabang()
    {
        return $this->belongsTo(Cabang::class, 'id_cabang', 'id_cabang');
    }

    /**
     * Mendefinisikan relasi "hasMany" ke model Rapat.
     */
    public function rapat()
    {
        return $this->hasMany(Rapat::class, 'id_room', 'id_room');
    }
}