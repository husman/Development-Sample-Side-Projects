<?php
/**
 * 
 * @author Haleeq Usman
 * 
 * MySQL driver will be deprecated soon. Use at own risk of future refactor. An
 * @ is prepended to all mysql_*() function calls to ignore deprecation warning.
 *
 */
namespace Ares\Db;

require_once BASEPATH.'backend/db/drivers/DatabaseDriver.php';
require_once BASEPATH.'backend/db/interfaces/iDatabaseDriver.php';

class MySQLDriver extends DatabaseDriver implements Interfaces\iDatabaseDriver {
	
	private static $obj;
	
	public static function getInstance()
	{	
		if(!self::$obj) {
			self::$obj = new MySQLDriver();
		}
		
		return self::$obj;
	}
	
	/**
	 * Selects the given MySQL database
	 *
	 * @param String $db_name - The name of the database/schema to use
	 *
	 * @return Boolean - True on success; False otherwise
	 */
	public function select_db($db_name)
	{
		if(!$this->conn) {
			return;
		}
	
		// Select the database
		return @mysql_select_db($db_name);
	}
	
	/**
	 * Connects to the MySQL database with the given parameters.
	 *
	 * @param String $db_host - Host/location of database server/instance
	 * @param String $db_user - Username to login with
	 * @param String $db_pass - Password to use for login
	 * 
	 * @return Identifer - Connection link on success; False otherwise
	 */
	public function connect($db_host, $db_user, $db_pass, $db_name)
	{	
		if(!$this->conn) {
			$this->conn = @mysql_connect($db_host, $db_user, $db_pass);
		}
		
		$this->select_db($db_name);
		
		return $this->conn;
	}
	
	/**
	 * Runs the given SQL query through the active database connection/schema
	 * 
	 * Care must be taken while utilizing this function.
	 * Ideally, an 'Active record' select function should be used.
	 * Through this approach, care must be taken to properly escape the fields.
	 *
	 * @param String $sql_query - The SQL statement to execute
	 *
	 * @return Identifer - Query resource on success; False otherwise
	 */
	public function query($sql_query)
	{
		// Unset result array so that the next call to result_*()
		// Will return any empty set or the actual record set.
		unset($this->result);
		
		// Run query. This is dangerous!
		$this->query = @mysql_query($sql_query);
		
		// Return the reference to the current object for chaining.
		return $this;
	}
	
	/**
	 * Fetches the results for the last executed query as an associative array
	 * 
	 * @return Array - An associative array of the record set.
	 */
	public function fetch_array()
	{
		// Fetch new results if necessary
		if (!isset($this->result)) {
			while($row = @mysql_fetch_array($this->query)) {
				$this->result[] = $row;
			}
		}
		
		return !empty($this->result)? $this->result : array();
	}
	
	/**
	 * Fetches the results for the last executed query as an object.
	 * This is the recommended approach for OOP normalization.
	 *
	 * @return Object - An Object representation of the record set.
	 * 
	 */
	public function fetch_all()
	{
		// Fetch new results if necessary
		if (!isset($this->result)) {
			while($row = @mysql_fetch_object($this->query)) {
				$this->result[] = $row;
			}
		}
	
		return !empty($this->result)? $this->result : Object();
	}
	
	/**
	 * The number of records returned in the last executed query.
	 *
	 * @return Integer - The number of rows returned for last query.
	 *
	 */
	public function num_rows()
	{
		if( !isset($this->query)) {
			return 0;
		}
		
		return @mysql_num_rows($this->query);
	}
	
	/**
	 *  The number of fields returned in the last executed query's table.
	 *
	 * @return Integer - The number of fields (or columns) in table for last query.
	 *
	 */
	public function num_fields()
	{
		if( !isset($this->query)) {
			return 0;
		}
		
		return @mysql_num_fields($this->query);
		
	}
	
	/**
	 * Name of the field at offset in the last executed query's table.
	 *
	 * @param Integer $offset - The index of the field/column starting from 0.
	 * 
	 * @return String - The name of the field (or columns)
	 * in table for last query at the specified offset.array
	 *
	 */
	public function field_name($offset)
	{
		if( !isset($this->query) || $offset < 0) {
			return '';
		}
		
		return @mysql_field_name($this->query, $offset);
	}
	
	/**
	 * Type of the field at offset in the last executed query's table.
	 *
	 * @param Integer $offset - The index of the field/column starting from 0.
	 *
	 * @return String - The type of the field (or columns)
	 * in table for last query at the specified offset.array
	 *
	 */
	public function field_type($offset)
	{
		if( !isset($this->query) || $offset < 0) {
			return '';
		}
		
		return @mysql_field_type($this->query, $offset);
	}
}
?>
