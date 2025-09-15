<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StatusRapat extends Model
{
    use HasFactory;

    protected $table = 'status_rapat';
    protected $primaryKey = 'id_status';

    protected $fillable = [
        'status_rapat',
        'desc',
    ];

    /**
     * Mendefinisikan relasi "hasMany" ke model Rapat.
     */
    public function rapat()
    {
        return $this->hasMany(Rapat::class, 'id_status', 'id_status');
    }
}