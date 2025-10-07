<?php

use App\Http\Controllers\Api\AbsensiController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CabangController;
use App\Http\Controllers\Api\RapatController;
use App\Http\Controllers\Api\RoomController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/userPIC', [AuthController::class, 'getUsersWithRole']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);

    Route::get('/rapat/saya', [RapatController::class, 'rapatSaya']);
    Route::apiResource('rapat', RapatController::class);
    Route::post('rapat/{id}/setujui', [RapatController::class, 'setujuiRapat']);
    Route::post('rapat/{id}/tolak', [RapatController::class, 'tolakRapat']);

    Route::post('/absensi', [AbsensiController::class, 'store']); // Untuk melakukan absensi
    Route::get('/absensi/history', [AbsensiController::class, 'history']); // Untuk melihat riwayat

    Route::get('/cabang/{cabang}/room', [RoomController::class, 'getRoomsByCabang']);
    Route::get('/cabang', [CabangController::class, 'index']);
    Route::get('/room', [RoomController::class, 'index']);

});

// // Tambahkan :id_cabang setelah {cabang}
// Route::get('/cabang/{cabang:id}/room', [RoomController::class, 'getRoomsByCabang']);
