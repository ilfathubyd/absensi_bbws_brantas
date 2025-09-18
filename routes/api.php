<?php


use App\Http\Controllers\Api\CabangController;
use App\Http\Controllers\Api\RoomController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\RapatController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);

});

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('rapat', RapatController::class);
});

Route::get('/cabang', [CabangController::class, 'index']);
Route::get('/room', [RoomController::class, 'index']);
