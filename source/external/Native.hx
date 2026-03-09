package external;

class Native
{
	/**
	 * Attempts to retrieve the actual task memory used by the application
	 * 
	 * Will fallback on `0.0` if it is not supported.
	 */
	public static function getTaskMemory()
	{
		#if cpp
		return external.memory.Memory.getCurrentUsage();
		#else
		return 0.0;
		#end
	}
}
