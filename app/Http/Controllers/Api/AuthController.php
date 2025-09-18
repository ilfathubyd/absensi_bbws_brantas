<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use App\Models\User;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $v = Validator::make($request->all(), [
            'username' => 'required|string|unique:users,username',
            'password' => 'required|string|min:1',
            'name'     => 'required|string',
            'phone'    => 'nullable|string',
            'id_role'    => 'nullable|integer',
            'gender'   => 'nullable|in:Male,Female',
            'id_division' => 'nullable|integer',
            'photo'    => 'nullable|image|max:2048',
        ]);

        if ($v->fails()) {
            return response()->json(['errors' => $v->errors()], 422);
        }

        $data = $v->validated();

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('photos', 'public');
            $data['photo'] = Storage::url($path);
        }

        $data['password'] = Hash::make($data['password']);

        $user = User::create($data);

        $token = $user->createToken('api_token')->plainTextToken;

        return response()->json([
            'user'  => $user,
            'token' => $token
        ], 201);
    }

    public function login(Request $request)
    {
        $v = Validator::make($request->all(), [
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        if ($v->fails()) {
            return response()->json(['errors' => $v->errors()], 422);
        }

        $user = User::where('username', $request->username)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }
        
        // PERBAIKAN: Muat relasi dengan eager loading
        $user->load(['role', 'division']);

        $token = $user->createToken('api_token')->plainTextToken;

        // PERBAIKAN: Response yang lebih aman dan konsisten
        return response()->json([
            'token' => $token,
            'user'  => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'email' => $user->email,
                'phone' => $user->phone,
                'gender' => $user->gender,
                'photo' => $user->photo,
                'id_role' => $user->id_role,
                'id_division' => $user->id_division,
                // PERBAIKAN: Menggunakan relasi dan accessor yang benar
                'role' => $user->role ? $user->role->role : null,
                'division' => $user->division ? $user->division->division_name : null,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
            ]
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out']);
    }

    public function profile(Request $request)
    {
        // Load relasi untuk response profile yang lengkap
        $user = $request->user()->load(['role', 'division']);
        
        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'email' => $user->email,
            'phone' => $user->phone,
            'gender' => $user->gender,
            'photo' => $user->photo,
            'id_role' => $user->id_role,
            'id_division' => $user->id_division,
            'role' => $user->role ? $user->role->role : null,
            'division' => $user->division ? $user->division->division_name : null,
            'created_at' => $user->created_at,
            'updated_at' => $user->updated_at,
        ]);
    }
}