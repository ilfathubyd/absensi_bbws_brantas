<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Division extends Model
{
    use HasFactory;

    protected $table = 'division';
    protected $primaryKey = 'id_division';

    protected $fillable = [
        'division_name',
    ];

    /**
     * Mendefinisikan relasi "hasMany" ke model User.
     */
    public function users()
    {
        return $this->hasMany(User::class, 'id_division', 'id_division');
    }
}