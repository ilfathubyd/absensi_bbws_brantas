<?php


use App\Http\Controllers\Api\CabangController;
use App\Http\Controllers\Api\RoomController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\RapatController;
use App\Http\Controllers\Api\AbsensiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);

});

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('rapat', RapatController::class);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/absensi', [AbsensiController::class, 'store']); // Untuk melakukan absensi
    Route::get('/absensi/history', [AbsensiController::class, 'history']); // Untuk melihat riwayat
});

Route::get('/cabang', [CabangController::class, 'index']);
Route::get('/room', [RoomController::class, 'index']);
