<?php

/* 

-- Script Name : MySQLDatabase.php
-- Author      : Mario Jimenez
-- Date        : November 17, 2018

*/

class Database
{
	var $sql;

	// Class Constructor with database info

	function __construct()
	{
		$this -> sql  = new mysqli('host', 'user', 'pass', 'database');
	}

	// Creates a random username with random password

	function CreateRandomUser()
	{
		$id = $this -> generateString(15);
		$pass = $this -> generateString(30);

		if ($this -> sql -> connect_errno) {
			printf('Connection Failed!');
			exit();
		}

		$q = $this -> sql -> query("SELECT * FROM Users WHERE Name = '".$id."'");
		$r = mysqli_fetch_array($q);
		$c = mysqli_num_rows($q);
		$q -> close();

		if ($c == 0) 
		{
			$this -> sql -> query("INSERT INTO Users (Name, Password) VALUES ('".$id."', '".$pass."')");			
			return printf($id.':'.$pass);
		}
		return printf('FAILED');
	}

	// Validates username and password

	function ValidateIdentity($id, $pass)
	{
		$i = $this -> sql -> real_escape_string($id);
		$k = $this -> sql -> real_escape_string($pass);

		if ($this -> sql -> connect_errno) {
			exit();
		}
		
		$q = $this -> sql -> query("SELECT * FROM Users WHERE Name = '".$i."'");
		$r = mysqli_fetch_array($q);
		$c = mysqli_num_rows($q);
		$q -> close();

		if ($c == 1  && $r['Password'] == $k)
		{
			return base64_encode("VALIDATED");
		}
		return  base64_encode("NOT VALIDATED");
	}

	// Closes Database Connection
	
	function Close()
	{
		$this -> sql -> close();
	}

	// Generates random string
	
	private function generateString($l  = 10)
	{
		$c = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
		$cLength = strlen($c);
		$str = '';
		for ($i = 0; $i < $l; $i++) {
			$str .= $c[rand(0, $cLength - 1)];
		}
		return $str;
	}
}
?>