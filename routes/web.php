<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json(['status' => 'ok to key', 'laravel' => app()->version()]);
});
