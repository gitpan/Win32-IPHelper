package Win32::IPHelper;

use 5.006;
use strict;
#use warnings;
use Carp;

use Socket;
use Win32;
use Win32::API;
use enum;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::IPHelper ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
	'all' => [ qw( AddIPAddress DeleteIPAddress GetIfEntry GetAdaptersInfo GetInterfaceInfo GetAdapterIndex IpReleaseAddress IpRenewAddress ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';

my $AddIPAddress = new Win32::API ('Iphlpapi', 'AddIPAddress', ['N', 'N', 'N', 'P', 'P'], 'N') or croak 'can\'t find AddIPAddress() function';
my $DeleteIPAddress = new Win32::API ('Iphlpapi', 'DeleteIPAddress', ['N'], 'N') or croak 'can\'t find DeleteIPAddress() function';
my $GetIfEntry = new Win32::API ('Iphlpapi', 'GetIfEntry', ['P'], 'N') or croak 'can\'t find GetIfEntry() function';
my $GetAdaptersInfo = new Win32::API ('Iphlpapi', 'GetAdaptersInfo', ['P', 'P'], 'N') or croak 'can\'t find GetAdaptersInfo() function';
my $GetInterfaceInfo = new Win32::API ('Iphlpapi', 'GetInterfaceInfo', ['P', 'P'], 'N') or croak 'can\'t find GetInterfaceInfo() function';
my $GetAdapterIndex = new Win32::API ('Iphlpapi', 'GetAdapterIndex', ['P', 'P'], 'N') or croak 'can\'t find GetAdapterIndex() function';
my $IpReleaseAddress = new Win32::API ('Iphlpapi', 'IpReleaseAddress', ['P'], 'N') or croak 'can\'t find IpReleaseAddress() function';
my $IpRenewAddress = new Win32::API ('Iphlpapi', 'IpRenewAddress', ['P'], 'N') or croak 'can\'t find IpRenewAddress() function';


# Preloaded methods go here.

use enum qw(
	NO_ERROR=0
	:MAX_INTERFACE_
		NAME_LEN=256
	:MAX_ADAPTER_
		ADDRESS_LENGTH=8
		DESCRIPTION_LENGTH=128
		NAME=128
		NAME_LENGTH=256
	:ERROR_
		SUCCESS=0
		NOT_SUPPORTED=50
		INVALID_PARAMETER=87
		BUFFER_OVERFLOW=111
		INSUFFICIENT_BUFFER=122
		NO_DATA=232
	:MAXLEN_
		IFDESCR=256
		PHYSADDR=8
);

our $DEBUG = 0;

#################################
# PUBLIC Functions (exportable) #
#################################

#######################################################################
# Win32::IPHelper::AddIPAddress()
#
# The AddIPAddress function adds the specified IP address to the
# specified adapter.
#
#######################################################################
# Usage:
#	$ret = AddIPAddress($Address, $IpMask, $IfIndex, \$NTEContext, \$NTEInstance);
#
# Output:
#	$ret = 0 for success, a number for error
#
# Input:
#	$Address = IP address to add
#	$IpMask  = Subnet Mask for IP address
#	$IfIndex = adapter index
#	
# Output:
#	\$NTEContext = ref to Net Table Entry context
#	\$NTEInstance = ref to Net Table Entry instance
#
#######################################################################
# function AddIPAddress
#
# The AddIPAddress function adds the specified IP address to the
# specified adapter.
#
#
#	DWORD AddIPAddress(
#		IPAddr Address,     // IP address to add
#		IPMask IpMask,      // subnet mask for IP address
#		DWORD IfIndex,      // index of adapter
#		PULONG NTEContext,  // Net Table Entry context
#		PULONG NTEInstance  // Net Table Entry Instance
#	);
#
#######################################################################
sub AddIPAddress
{
	if(scalar(@_) ne 5)
	{
		croak 'Usage: AddIPAddress(\$Address, \$IpMask, \$IfIndex, \\\$NTEContext, \\\$NTEInstance)';
	}
	
	my $Address = unpack('L', inet_aton(shift));
	my $IpMask = unpack('L', inet_aton(shift));
	my $IfIndex = shift;
	
	my $NTEContext = shift;
	my $NTEInstance = shift;

#	$AddIPAddress = new Win32::API ('Iphlpapi', 'AddIPAddress', ['N', 'N', 'N', 'P', 'P'], 'N') or croak 'can\'t find AddIPAddress() function';
	
	# initialize area for the NTE data
	$$NTEContext = pack("L", 0);
	$$NTEInstance = pack("L", 0);
	
	# function call
	my $ret = $AddIPAddress->Call($Address, $IpMask, $IfIndex, $$NTEContext, $$NTEInstance);

	if($ret != NO_ERROR)
	{
		$DEBUG and carp sprintf "AddIPAddress() %s\n", Win32::FormatMessage($ret);
	}

	# unpack values...
	$$NTEContext = unpack("L", $$NTEContext);
	$$NTEInstance = unpack("L", $$NTEInstance);

	return $ret;
}

#######################################################################
# Win32::IPHelper::DeleteIPAddress()
#
# The DeleteIPAddress function deletes an IP address previously added
# using AddIPAddress.
#
#######################################################################
# Usage:
#	$ret = DeleteIPAddress($NTEContext);
#
# Output:
#	$ret = 0 for success, a number for error
#
# Input:
#	$NTEContext = Net Table Entry context
#
#######################################################################
# function DeleteIPAddress
#
# The DeleteIPAddress function deletes an IP address previously added
# using AddIPAddress.
#
#
#	DWORD DeleteIPAddress(
#		ULONG NTEContext  // Net Table Entry context
#	);
#
#######################################################################
sub DeleteIPAddress
{
	if(scalar(@_) ne 1)
	{
		croak 'Usage: DeleteIPAddress(\$NTEContext)';
	}

	my $NTEContext = pack("L", shift);

#	$DeleteIPAddress = new Win32::API ('Iphlpapi', 'DeleteIPAddress', ['N'], 'N') or croak 'can\'t find DeleteIPAddress() function';

	# function call
	my $ret = $DeleteIPAddress->Call(unpack('L', $NTEContext));

	if($ret != NO_ERROR)
	{
		$DEBUG and carp sprintf "DeleteIPAddress() %s\n", Win32::FormatMessage($ret);
	}

	return $ret;
}

#######################################################################
# Win32::IPHelper::GetIfEntry()
#
# The GetIfEntry function retrieves information for the specified
# interface on the local computer.
#
#######################################################################
# Usage:
#	$ret = GetIfEntry($IfIndex, \%pIfRow);
#
# Output:
#	$ret = 0 for success, a number for error
#
# Input:
#	$IfIndex = adapter index
#	
# Output:
#	\%pIfRow = ref to the data structure
#
#######################################################################
# function GetIfEntry
#
# The GetIfEntry function retrieves information for the specified
# interface on the local computer.
#
#	DWORD GetIfEntry(
#		PMIB_IFROW pIfRow  // pointer to interface entry 
#	);
#
#
#######################################################################
sub GetIfEntry
{
	if(scalar(@_) ne 2)
	{
		croak 'Usage: GetIfEntry(\$IfIndex, \\\%pIfRow)';
	}

	my $IfIndex = shift;
	my $buffer = shift;

#	$GetIfEntry = new Win32::API ('Iphlpapi', 'GetIfEntry', ['P'], 'N') or croak 'can\'t find GetIfEntry() function';

	my $lpBuffer;
	$lpBuffer .= pack("C@".MAX_INTERFACE_NAME_LEN*2, 0);
	$lpBuffer .= pack("L", $IfIndex);
	$lpBuffer .= pack("L@".16, 0);
	$lpBuffer .= pack("C@".MAXLEN_PHYSADDR, 0);
	$lpBuffer .= pack("L@".64, 0);
	$lpBuffer .= pack("C@".MAXLEN_IFDESCR, 0);

	# first call just to read the size
	my $ret = $GetIfEntry->Call($lpBuffer);
	
	if($ret != NO_ERROR)
	{
		$DEBUG and carp sprintf "GetIfEntry() %s\n", Win32::FormatMessage($ret);
	}
	else
	{
		(undef, %$buffer) = _MIB_IFROW(\$lpBuffer, 0);
	}

	return $ret;
}

#######################################################################
# Win32::IPHelper::GetAdaptersInfo()
#
# The GetAdaptersInfo function retrieves adapter information for the
# local computer.
#
#######################################################################
# Usage:
#	$ret = GetAdaptersInfo(\@IP_ADAPTER_INFO);
#
# Output:
#	$ret = 0 for success, a number for error
#
# Input:
#	\@array = reference to the array to be filled with decoded data
#
#######################################################################
# function GetAdaptersInfo
#
# The GetAdaptersInfo function retrieves adapter information for the
# local computer.
#
#	DWORD GetAdaptersInfo(
#		PIP_ADAPTER_INFO pAdapterInfo,  // buffer to receive data
#		PULONG pOutBufLen               // size of data returned
#	);
#
#######################################################################
sub GetAdaptersInfo
{
	if(scalar(@_) ne 1)
	{
		croak 'Usage: GetAdaptersInfo(\\\@IP_ADAPTER_INFO)';
	}

	my $buffer = shift;
	my $base_size = 4;
	
#	$GetAdaptersInfo = new Win32::API ('Iphlpapi', 'GetAdaptersInfo', ['P', 'P'], 'N') or croak 'can\'t find GetAdaptersInfo() function';

	# initialize area for the buffer size
	my $lpSize = pack("L", 0);
	my $lpBuffer = pack("L@".$base_size, 0);

	# first call just to read the size
	my $ret = $GetAdaptersInfo->Call($lpBuffer, $lpSize);
	
	# check returned value...
	if($ret == ERROR_NOT_SUPPORTED)
	{
		carp "GetAdaptersInfo() is not supported on this platform\n";
		return $ret;
	}
	elsif($ret == ERROR_NO_DATA)
	{
		carp "GetAdaptersInfo() found no adapter information for the local computer\n";
		return $ret;
	}
	elsif($ret == ERROR_INVALID_PARAMETER)
	{
		carp "GetAdaptersInfo() encoutered an error reading/writing a buffer\n";
		return $ret;
	}
	elsif($ret != ERROR_BUFFER_OVERFLOW)
	{
		carp sprintf "GetAdaptersInfo() %s\n", Win32::FormatMessage($ret);
		return $ret;
	}

	# initialize area for the buffer content
	$base_size = unpack("L", $lpSize);
	$lpBuffer = pack("L@".$base_size, 0);

	# second call to read data
	$ret = $GetAdaptersInfo->Call($lpBuffer, $lpSize);
	
	# check returned value...
	if($ret == ERROR_NOT_SUPPORTED)
	{
		$DEBUG and carp "GetAdaptersInfo() is not supported on this platform\n";
		return $ret;
	}
	elsif($ret == ERROR_NO_DATA)
	{
		$DEBUG and carp "GetAdaptersInfo() found no adapter information for the local computer\n";
		return $ret;
	}
	elsif($ret == ERROR_INVALID_PARAMETER)
	{
		$DEBUG and carp "GetAdaptersInfo() encoutered an error reading/writing a buffer\n";
		return $ret;
	}
	elsif($ret == ERROR_BUFFER_OVERFLOW)
	{
		$DEBUG and carp "GetAdaptersInfo() buffer overflow on the second call\n";
		return $ret;
	}
	elsif($ret != ERROR_SUCCESS)
	{
		$DEBUG and carp sprintf "GetAdaptersInfo() %s\n", Win32::FormatMessage($ret);
		return $ret;
	}

	# decode data into the supplied buffer area
	(undef, @$buffer) = _IP_ADAPTER_INFO(\$lpBuffer, 0);

	return 0;
}


#######################################################################
# Win32::IPHelper::GetInterfaceInfo()
#
# The GetInterfaceInfo function obtains a list of the network interface
# adapters on the local system.
#
#######################################################################
# Usage:
#	$ret = GetInterfaceInfo(\%IP_INTERFACE_INFO);
#
# Output:
#	$ret = 0 for success, a number for error
#
# Input:
#	\%hash = reference to the hash to be filled with decoded data
#
#######################################################################
# function GetInterfaceInfo
#
# The GetInterfaceInfo function obtains a list of the network interface
# adapters on the local system. 
#
#	DWORD GetInterfaceInfo(
#		PIP_INTERFACE_INFO pIfTable,  // buffer to receive info
#		PULONG dwOutBufLen            // size of buffer 
#	);
#
#######################################################################
sub GetInterfaceInfo
{
	if(scalar(@_) ne 1)
	{
		croak 'Usage: GetInterfaceInfo(\\\%IP_INTERFACE_INFO)';
	}

	my $buffer = shift;
	my $base_size = 4;
	
#	$GetInterfaceInfo = new Win32::API ('Iphlpapi', 'GetInterfaceInfo', ['P', 'P'], 'N') or croak 'can\'t find GetInterfaceInfo() function';

	# initialize area for the buffer size
	my $lpBuffer = pack("L@".$base_size, 0);
	my $lpSize = pack("L", 0);

	# first call just to read the size
	my $ret = $GetInterfaceInfo->Call($lpBuffer, $lpSize);
	
	# check returned value...
	if($ret == ERROR_NOT_SUPPORTED)
	{
		$DEBUG and carp "GetInterfaceInfo() is not supported on this platform\n";
		return $ret;
	}
	elsif($ret == ERROR_INVALID_PARAMETER)
	{
		$DEBUG and carp "GetInterfaceInfo() encoutered an error reading/writing a buffer\n";
		return $ret;
	}
	elsif($ret != ERROR_INSUFFICIENT_BUFFER)
	{
		$DEBUG and carp sprintf "GetInterfaceInfo() %s\n", Win32::FormatMessage($ret);
		return $ret;
	}

	# initialize area for the buffer content
	$base_size = unpack("L", $lpSize);
	$lpBuffer = pack("L@".$base_size, 0);

	# second call to read data
	$ret = $GetInterfaceInfo->Call($lpBuffer, $lpSize);
	
	# check returned value...
	if($ret == ERROR_NOT_SUPPORTED)
	{
		$DEBUG and carp "GetInterfaceInfo() is not supported on this platform\n";
		return $ret;
	}
	elsif($ret == ERROR_INVALID_PARAMETER)
	{
		$DEBUG and carp "GetInterfaceInfo() encoutered an error reading/writing a buffer\n";
		return $ret;
	}
	elsif($ret == ERROR_INSUFFICIENT_BUFFER)
	{
		$DEBUG and carp "GetInterfaceInfo() buffer overflow on the second call\n";
		return $ret;
	}
	elsif($ret != ERROR_SUCCESS)
	{
		$DEBUG and carp sprintf "GetInterfaceInfo() %s\n", Win32::FormatMessage($ret);
		return $ret;
	}
	
	# decode data into the supplied buffer area
	(undef, %$buffer) = _IP_INTERFACE_INFO(\$lpBuffer, 0);

	return 0;
}


#######################################################################
# Win32::IPHelper::GetAdapterIndex(\$AdapterName, \$IfIndex)
#
# The GetAdapterIndex function obtains the index of an adapter, given
# its name.
#
#######################################################################
#
# Prototype
#	DWORD GetAdapterIndex(
#		LPWSTR AdapterName,
#		PULONG IfIndex
#	);
#
# Parameters
#	AdapterName 
#		[in] Pointer to a Unicode string that specifies the name of the adapter. 
#	IfIndex 
#		[out] Pointer to a ULONG variable that points to the index of the adapter. 
#
# Return Values
#	If the function succeeds, the return value is NO_ERROR.
#	If the function fails, use FormatMessage to obtain the message string for the returned error.
#
#######################################################################
sub GetAdapterIndex
{
	if(scalar(@_) ne 2)
	{
		croak 'Usage: GetAdapterIndex(\\\$AdapterName, \\\$IfIndex)';
	}

	my $AdapterName = shift;
	my $IfIndex = shift;
	
	# prepare the buffer for IfIndex
	$$IfIndex = pack('L', 0);
	
#	$GetAdapterIndex = new Win32::API ('Iphlpapi', 'GetAdapterIndex', ['P', 'P'], 'N') or croak 'can\'t find GetAdapterIndex() function';
	
	# function call
	my $ret = $GetAdapterIndex->Call(_ToUnicodeSz('\DEVICE\TCPIP_'.$$AdapterName), $$IfIndex);
	
	if($ret != NO_ERROR)
	{
		$DEBUG and carp sprintf "GetAdapterIndex() %s\n", Win32::FormatMessage($ret);
	}
	
	# unpack IfIndex for later use
	$$IfIndex = unpack('L', $$IfIndex);

	return $ret;
}


#######################################################################
# Win32::IPHelper::IpReleaseAddress(\%IP_ADAPTER_INDEX_MAP)
#
# The IpReleaseAddress function releases an IP address previously
# obtained through Dynamic Host Configuration Protocol (DHCP).
#
#######################################################################
#
# Prototype
#	DWORD IpReleaseAddress(
#		PIP_ADAPTER_INDEX_MAP AdapterInfo
#	);
#
# Parameters
#	AdapterInfo 
#		[in] Pointer to an IP_ADAPTER_INDEX_MAP structure that
#			specifies the adapter associated with the IP address to release. 
#
# Return Values
#	If the function succeeds, the return value is NO_ERROR.
#	If the function fails, use FormatMessage to obtain the message string for the returned error.
#
#######################################################################
sub IpReleaseAddress
{
	if(scalar(@_) ne 1)
	{
		croak 'Usage: IpReleaseAddress(\\\%IP_ADAPTER_INDEX_MAP)';
	}

	my $AdapterInfo = shift;
	
	# prepare the IP_ADAPTER_INDEX_MAP structure
	my $ip_adapter_index_map = pack("L", $$AdapterInfo{'Index'});
	$ip_adapter_index_map .= pack("Z*@".(2 * MAX_ADAPTER_NAME), _ToUnicodeSz($$AdapterInfo{'Name'})); 
	
#	$IpReleaseAddress = new Win32::API ('Iphlpapi', 'IpReleaseAddress', ['P'], 'N') or croak 'can\'t find IpReleaseAddress() function';
	
	# function call
	my $ret = $IpReleaseAddress->Call($ip_adapter_index_map);
	
	if($ret != NO_ERROR)
	{
		$DEBUG and carp sprintf "IpReleaseAddress() %s\n", Win32::FormatMessage($ret);
	}
	return $ret;
}


#######################################################################
# Win32::IPHelper::IpRenewAddress(\%IP_ADAPTER_INDEX_MAP)
#
# The IpRenewAddress function renews a lease on an IP address previously
# obtained through Dynamic Host Configuration Protocol (DHCP).
#
#######################################################################
#
# Prototype
#	DWORD IpRenewAddress(
#		PIP_ADAPTER_INDEX_MAP AdapterInfo
#	);
#
# Parameters
#	AdapterInfo 
#		[in] Pointer to an IP_ADAPTER_INDEX_MAP structure that
#			specifies the adapter associated with the IP address to renew. 
#
# Return Values
#	If the function succeeds, the return value is NO_ERROR.
#	If the function fails, use FormatMessage to obtain the message string for the returned error.
#
#######################################################################
sub IpRenewAddress
{
	if(scalar(@_) ne 1)
	{
		croak 'Usage: IpRenewAddress(\\\%IP_ADAPTER_INDEX_MAP)';
	}

	my $AdapterInfo = shift;
	
	# prepare the IP_ADAPTER_INDEX_MAP structure
	my $ip_adapter_index_map = pack("L", $$AdapterInfo{'Index'});
	$ip_adapter_index_map .= pack("Z*@".(2 * MAX_ADAPTER_NAME), _ToUnicodeSz($$AdapterInfo{'Name'})); 
	
#	$IpRenewAddress = new Win32::API ('Iphlpapi', 'IpRenewAddress', ['P'], 'N') or croak 'can\'t find IpRenewAddress() function';
	
	# function call
	my $ret = $IpRenewAddress->Call($ip_adapter_index_map);
	
	if($ret != NO_ERROR)
	{
		$DEBUG and carp sprintf "IpRenewAddress() %s\n", Win32::FormatMessage($ret);
	}
	return $ret;
}


####################################
# PRIVATE Functions (not exported) #
####################################

#######################################################################
# _MIB_IFROW()
#
# The MIB_IFROW structure stores information about a particular
# interface.
#
#######################################################################
# Usage:
#	($pos, %hash) = _MIB_IFROW(\$buffer, $position);
#
# Output:
#	$pos   = new position in buffer (for the next call)
#	%hash  = the decoded data structure
#
# Input:
#	\$buffer = reference to the buffer to decode
#	$position = first byte to decode
#
#######################################################################
# struct MIB_IFROW
#
# The MIB_IFROW structure stores information about a particular
# interface.
#
#	typedef struct _MIB_IFROW {
#		WCHAR   wszName[MAX_INTERFACE_NAME_LEN];
#		DWORD   dwIndex;    // index of the interface
#		DWORD   dwType;     // type of interface
#		DWORD   dwMtu;      // max transmission unit 
#		DWORD   dwSpeed;    // speed of the interface 
#		DWORD   dwPhysAddrLen;    // length of physical address
#		BYTE    bPhysAddr[MAXLEN_PHYSADDR]; // physical address of adapter
#		DWORD   dwAdminStatus;    // administrative status
#		DWORD   dwOperStatus;     // operational status
#		DWORD   dwLastChange;     // last time operational status changed 
#		DWORD   dwInOctets;       // octets received
#		DWORD   dwInUcastPkts;    // unicast packets received 
#		DWORD   dwInNUcastPkts;   // non-unicast packets received 
#		DWORD   dwInDiscards;     // received packets discarded 
#		DWORD   dwInErrors;       // erroneous packets received 
#		DWORD   dwInUnknownProtos;  // unknown protocol packets received 
#		DWORD   dwOutOctets;      // octets sent 
#		DWORD   dwOutUcastPkts;   // unicast packets sent 
#		DWORD   dwOutNUcastPkts;  // non-unicast packets sent 
#		DWORD   dwOutDiscards;    // outgoing packets discarded 
#		DWORD   dwOutErrors;      // erroneous packets sent 
#		DWORD   dwOutQLen;        // output queue length 
#		DWORD   dwDescrLen;       // length of bDescr member 
#		BYTE    bDescr[MAXLEN_IFDESCR];  // interface description 
#	} MIB_IFROW,*PMIB_IFROW;
#
#######################################################################
sub _MIB_IFROW
{
	my ($buffer, $pos) = @_;
	my %hash;
	
	($pos, $hash{'Name'})            = _shiftunpack($buffer, $pos, MAX_INTERFACE_NAME_LEN*2, "Z" . MAX_INTERFACE_NAME_LEN*2);
	($pos, $hash{'Index'})           = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'Type'})            = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'Mtu'})             = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'Speed'})           = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'PhysAddrLen'})     = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'PhysAddr'})        = _shiftunpack($buffer, $pos, MAXLEN_PHYSADDR, "H" . MAXLEN_PHYSADDR * 2);
	($pos, $hash{'AdminStatus'})     = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'OperStatus'})      = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'LastChange'})      = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'InOctets'})        = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'InUcastPkts'})     = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'InNUcastPkts'})    = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'InDiscards'})      = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'InErrors'})        = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'InUnknownProtos'}) = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'OutOctets'})       = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'OutUcastPkts'})    = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'OutNUcastPkts'})   = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'OutDiscards'})     = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'OutErrors'})       = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'OutQLen'})         = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'DescrLen'})        = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'Descr'})           = _shiftunpack($buffer, $pos, MAXLEN_IFDESCR, "Z" . MAXLEN_IFDESCR * 2);

	return ($pos, %hash);
}


#######################################################################
# _IP_ADAPTER_INFO()
#
# Decodes an IP_ADAPTER_INFO data structure and returns data
# into a Perl array
#
#######################################################################
# Usage:
#	($pos, @array) = _IP_ADAPTER_INFO(\$buffer, $position);
#
# Output:
#	$pos   = new position in buffer (for the next call)
#	@array = the decoded data structure
#
# Input:
#	\$buffer = reference to the buffer to decode
#	$position = first byte to decode
#
#######################################################################
# struct IP_ADAPTER_INFO
#
# The IP_ADAPTER_INFO structure contains information about a particular
# network adapter on the local computer.
#
#	typedef struct _IP_ADAPTER_INFO {
#		struct _IP_ADAPTER_INFO* Next;
#		DWORD ComboIndex;
#		char AdapterName[MAX_ADAPTER_NAME_LENGTH + 4];
#		char Description[MAX_ADAPTER_DESCRIPTION_LENGTH + 4];
#		UINT AddressLength;
#		BYTE Address[MAX_ADAPTER_ADDRESS_LENGTH];
#		DWORD Index;
#		UINT Type;
#		UINT DhcpEnabled;
#		PIP_ADDR_STRING CurrentIpAddress;
#		IP_ADDR_STRING IpAddressList;
#		IP_ADDR_STRING GatewayList;
#		IP_ADDR_STRING DhcpServer;
#		BOOL HaveWins;
#		IP_ADDR_STRING PrimaryWinsServer;
#		IP_ADDR_STRING SecondaryWinsServer;
#		time_t LeaseObtained;
#		time_t LeaseExpires; 
#	} IP_ADAPTER_INFO, *PIP_ADAPTER_INFO;
#
#######################################################################
sub _IP_ADAPTER_INFO
{
	my ($buffer, $pos) = @_;
	my $size = 640;
	my %hash;
	my @array;
	my $next;
	
	($pos, $next) =_shiftunpack($buffer, $pos, 4, "P".$size);

	($pos, $hash{'ComboIndex'})    = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'AdapterName'})   = _shiftunpack($buffer, $pos, (MAX_ADAPTER_NAME_LENGTH + 4), "Z" . (MAX_ADAPTER_NAME_LENGTH + 4));
	($pos, $hash{'Description'})   = _shiftunpack($buffer, $pos, (MAX_ADAPTER_DESCRIPTION_LENGTH + 4), "Z" . (MAX_ADAPTER_DESCRIPTION_LENGTH + 4));
	($pos, $hash{'AddressLength'}) = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'Address'})       = _shiftunpack($buffer, $pos, MAX_ADAPTER_ADDRESS_LENGTH, "H" . MAX_ADAPTER_ADDRESS_LENGTH * 2);
	($pos, $hash{'Index'})         = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'Type'})          = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'DhcpEnabled'})   = _shiftunpack($buffer, $pos, 4, "L");

	my $CurrentIpAddress;
	($pos, $CurrentIpAddress) = _shiftunpack($buffer, $pos, 4, "P40");
	if($CurrentIpAddress)
	{
		@{ $hash{'CurrentIpAddress'} } = _IP_ADDR_STRING(\$CurrentIpAddress, 0);
	}

	($pos, @{ $hash{'IpAddressList'} }) = _IP_ADDR_STRING($buffer, $pos);

	($pos, @{ $hash{'GatewayList'} }) = _IP_ADDR_STRING($buffer, $pos);
	($pos, @{ $hash{'DhcpServer'} })  = _IP_ADDR_STRING($buffer, $pos);

	($pos, $hash{'HaveWins'}) = _shiftunpack($buffer, $pos, 4, "L");

	($pos, @{ $hash{'PrimaryWinsServer'} })   = _IP_ADDR_STRING($buffer, $pos);
	($pos, @{ $hash{'SecondaryWinsServer'} }) = _IP_ADDR_STRING($buffer, $pos);

	($pos, $hash{'LeaseObtained'}) =_shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'LeaseExpires'})  =_shiftunpack($buffer, $pos, 4, "L");

	push @array, \%hash;

	if($next)
	{
		my ($pos, @results) = _IP_ADAPTER_INFO(\$next, 0);
		push @array, @results;
	}

	return ($pos, @array);
}

#######################################################################
# _IP_ADDR_STRING()
#
# Decodes an _IP_ADDR_STRING data structure and returns data
# into a Perl array
#
#######################################################################
# Usage:
#	($pos, @array) = _IP_ADDR_STRING(\$buffer, $position);
#
# Output:
#	$pos   = new position in buffer (for the next call)
#	@array = the decoded data structure
#
# Input:
#	\$buffer = reference to the buffer to decode
#	$position = first byte to decode
#
#######################################################################
# struct IP_ADDR_STRING
#
# The IP_ADDR_STRING structure represents a node in a linked-list
# of IP addresses.
#
#	typedef struct _IP_ADDR_STRING {
#		struct _IP_ADDR_STRING* Next;
#		IP_ADDRESS_STRING IpAddress;
#		IP_MASK_STRING IpMask;
#		DWORD Context;
#	} IP_ADDR_STRING, *PIP_ADDR_STRING;
#
#######################################################################
sub _IP_ADDR_STRING
{
	my ($buffer, $pos) = @_;
	my $size = 40;
	my %hash;
	my @array;
	my $next;
	
	($pos, $next) = _shiftunpack($buffer, $pos, 4, "P".$size);
	
	($pos, $hash{'IpAddress'}) = _shiftunpack($buffer, $pos, 16, "Z16");
	($pos, $hash{'IpMask'})    = _shiftunpack($buffer, $pos, 16, "Z16");
	($pos, $hash{'Context'})   = _shiftunpack($buffer, $pos, 4, "L");

	push @array, \%hash;

	if($next)
	{
		my ($pos, @results) = _IP_ADDR_STRING(\$next, 0);
		push @array, @results;
	}

	return ($pos, @array);
}

#######################################################################
# _IP_ADAPTER_INDEX_MAP()
#
# Decodes an _IP_ADAPTER_INDEX_MAP data structure and returns data
# into a Perl hash
#
#######################################################################
# Usage:
#	($pos, %hash) = _IP_ADAPTER_INDEX_MAP(\$buffer, $position);
#
# Output:
#	$pos   = new position in buffer (for the next call)
#	%hash  = the decoded data structure
#
# Input:
#	\$buffer = reference to the buffer to decode
#	$position = first byte to decode
#
#######################################################################
# struct IP_ADAPTER_INDEX_MAP
#
# The IP_ADAPTER_INDEX_MAP structure pairs an adapter name with
# the index of that adapter.
#
#	typedef struct _IP_ADAPTER_INDEX_MAP {
#		ULONG Index // adapter index 
#		WCHAR Name [MAX_ADAPTER_NAME]; // name of the adapter 
#	} IP_ADAPTER_INDEX_MAP, * PIP_ADAPTER_INDEX_MAP;
#
#######################################################################
sub _IP_ADAPTER_INDEX_MAP
{
	my $size = 4 + 4;
	wantarray or return $size;

	my ($buffer, $pos) = @_;
	my %hash;
	my $NamePtr;

	($pos, $hash{'Index'}) = _shiftunpack($buffer, $pos, 4, "L");
	($pos, $hash{'Name'})  = _shiftunpackWCHAR($buffer, $pos, (2 * MAX_ADAPTER_NAME));

	return ($pos, %hash);
}


#######################################################################
# _IP_INTERFACE_INFO()
#
# Decodes an _IP_INTERFACE_INFO data structure and returns data
# into a Perl array
#
#######################################################################
# Usage:
#	($pos, @array) = _IP_INTERFACE_INFO(\$buffer, $position);
#
# Output:
#	$pos   = new position in buffer (for the next call)
#	@array = the decoded data structure
#
# Input:
#	\$buffer = reference to the buffer to decode
#	$position = first byte to decode
#
#######################################################################
# struct IP_INTERFACE_INFO
#
# The IP_INTERFACE_INFO structure contains a list of the network
# interface adapters on the local system.
#
#	typedef struct _IP_INTERFACE_INFO {
#		LONG NumAdapters;                 // number of adapters in array 
#		IP_ADAPTER_INDEX_MAP Adapter[1];  // adapter indices and names 
#	} IP_INTERFACE_INFO,*PIP_INTERFACE_INFO;
#
#######################################################################
sub _IP_INTERFACE_INFO
{
	my $size = 4 + 4;
	wantarray or return $size;

	my ($buffer, $pos) = @_;
	my %hash;
	my @array;
	
	($pos, $hash{'NumAdapters'}) = _shiftunpack($buffer, $pos, 4, "l");
	
	for(my $cnt=0; $cnt < $hash{'NumAdapters'}; $cnt++)
	{
		my %map;
		($pos, %map) = _IP_ADAPTER_INDEX_MAP($buffer, $pos);
		push @{ $hash{'Adapters'} }, \%map;
	}

	return ($pos, %hash);
}


#######################################################################
# _shiftunpack
#
# Decodes a part of a given buffer and returns data and new position
#
#######################################################################
# Usage:
#	($pos, $value) = _shiftunpack(\$buffer, $position, $size, $element);
#
# Output:
#	$pos   = new position in buffer (for the next call)
#	$value = the decoded data value
#
# Input:
#	\$buffer  = reference to the buffer to decode
#	$position = first byte to decode
#	$size     = number of bytes to decode
#	$element  = type of data to decode (see 'pack()' in Perl functions)
#
#######################################################################
sub _shiftunpack
{
	my ($buffer, $position, $size, $element) = @_;

	my $buf = substr($$buffer, $position, $size);
	my $value = unpack($element, $buf);
	
	$position += $size;
	
	return($position, $value);
}


#######################################################################
# _shiftunpackWCHAR
#
# Decodes a UNICODE part of a given buffer and returns data and new
# position
#
#######################################################################
# Usage:
#	($pos, $value) = _shiftunpackWCHAR(\$buffer, $position, $size);
#
# Output:
#	$pos   = new position in buffer (for the next call)
#	$value = the decoded data value
#
# Input:
#	\$buffer  = reference to the buffer to decode
#	$position = first byte to decode
#	$size     = number of bytes to decode
#
#######################################################################
sub _shiftunpackWCHAR
{
	my ($buffer, $position, $size) = @_;

	my $buf = substr($$buffer, $position, $size);
	my $value = pack( "C*", unpack("S*", $buf));
	$value = unpack("Z*", $value);

	$position += $size;
	
	return($position, $value);
}


#######################################################################
# _debugbuffer
#
# Decodes and prints the content of a buffer
#
#######################################################################
# Usage:
#	_debugbuffer(\$buffer);
#
# Input:
#	\$buffer  = reference to the buffer to print
#
#######################################################################
sub _debugbuffer
{
	my $buffer = $_[0];

	my (@data) = unpack("C*", $$buffer);

	printf "Buffer size: %d\n", scalar(@data);

	my $cnt = 0;

	foreach my $i (@data)
	{
		my $char = '';
		if(32 <= $i  and $i < 127)
		{
			$char = chr($i);
		}
		printf "%03d -> 0x%02x --> %03d ---> %s\n", $cnt++, $i, $i, $char;
	}
}


#######################################################################
# WCHAR = _ToUnicodeChar(string)
# converts a perl string in a 16-bit (pseudo) unicode string
#######################################################################
sub _ToUnicodeChar
{
	my $string = shift or return(undef);

	$string =~ s/(.)/$1\x00/sg;
	
	return $string;
}


#######################################################################
# WSTR = _ToUnicodeSz(string)
# converts a perl string in a null-terminated 16-bit (pseudo) unicode string
#######################################################################
sub _ToUnicodeSz
{
	my $string = shift or return(undef);

	return _ToUnicodeChar($string."\x00");
}


#######################################################################
# string = _FromUnicode(WSTR)
# converts a null-terminated 16-bit unicode string into a regular perl string
#######################################################################
sub _FromUnicode
{
	my $string = shift or return(undef);
	
	$string = unpack("Z*", pack( "C*", unpack("S*", $string)));
	
	return($string);
}


1;
__END__

=head1 NAME

Win32::IPHelper - Perl wrapper for Win32 IP Helper functions and structures.

=head1 SYNOPSIS

 use Win32::IPHelper;

 $ret = Win32::IPHelper::GetInterfaceInfo(\%IP_INTERFACE_INFO);

 $ret = Win32::IPHelper::GetAdaptersInfo(\@IP_ADAPTER_INFO);

 $ret = Win32::IPHelper::GetAdapterIndex(\$AdapterName, \$IfIndex);

 $ret = Win32::IPHelper::GetIfEntry($IfIndex, \%MIB_IFROW);

 $ret = Win32::IPHelper::AddIPAddress($Address, $IpMask, $IfIndex, \$NTEContext, \$NTEInstance);

 $ret = Win32::IPHelper::DeleteIPAddress($NTEContext);

 $ret = Win32::IPHelper::IpReleaseAddress(\%AdapterInfo);

 $ret = Win32::IPHelper::IpRenewAddress(\%AdapterInfo);

=head1 DESCRIPTION

Interface to Win32 IP Helper functions and data structures, needed to retrieve and modify configuration settings for the Transmission Control Protocol/Internet Protocol (TCP/IP) transport on the local computer.

This module covers a small subset of the functions and data structures provided by the Win32 IP Helper API.

B<Purpose>

The Internet Protocol Helper (IP Helper) API enables the retrieval and modification of network configuration settings for the local computer.

B<Where Applicable>

The IP Helper API is applicable in any computing environment where programmatically manipulating TCP/IP configuration is useful.
Typical applications include IP routing protocols and Simple Network Management Protocol (SNMP) agents.

B<Developer Audience>

The IP Helper API is designed for use by C/C++ programmers. Programmers should also be familiar with TCP/IP networking concepts.

B<Run-time Requirements>

The IP Helper API is supported on:

=over 4

=item *
Microsoft Windows 98

=item *
Microsoft Windows Millennium Edition

=item *
Microsoft Windows NT version 4.0 with Service Pack 4

=item *
Microsoft Windows 2000

=item *
Microsoft Windows XP

=item *
Microsoft Windows .NET Server 2003 family

=back

B<Note>

Not all operating systems support all functions.
If an IP Helper function is called on a platform that does not support the function, ERROR_NOT_SUPPORTED is returned.
For more specific information about which operating systems support a particular function, refer to the Requirements sections in the documentation.

The complete SDK Reference documentation is available online through Microsoft MSDN Library (http://msdn.microsoft.com/library/default.asp)

=head2 EXPORT

None by default.

=head1 FUNCTIONS


=head2 GetInterfaceInfo(\%IP_INTERFACE_INFO)

The GetInterfaceInfo function obtains a IP_INTERFACE_INFO structure that contains the list of the network interface adapters on the local system.

B<Example>

  use Win32::IPHelper;
  use Data::Dumper;

  my %IP_INTERFACE_INFO;
  $ret = Win32::IPHelper::GetInterfaceInfo(\%IP_INTERFACE_INFO);

  if($ret == 0)
  {
    print Data::Dumper->Dump([\%IP_INTERFACE_INFO], [qw(IP_INTERFACE_INFO)]);
  }
  else
  {
    printf "GetInterfaceInfo() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Remarks>

The GetAdaptersInfo and GetInterfaceInfo functions do not return information about the loopback interface

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional, Windows Me, Windows 98. 
Server: Included in Windows .NET Server 2003, Windows 2000 Server. 
Header: Declared in Iphlpapi.h. 
Library: Iphlpapi.dll. 


=head2 GetAdaptersInfo(\@IP_ADAPTER_INFO)

The GetAdaptersInfo function obtains a list of IP_ADAPTER_INFO structures that contains adapter information for the local computer.

B<Examples>

  use Win32::IPHelper;
  use Data::Dumper;

  my @IP_ADAPTER_INFO;
  $ret = Win32::IPHelper::GetAdaptersInfo(\@IP_ADAPTER_INFO);

  if($ret == 0)
  {
    print Data::Dumper->Dump([\@IP_ADAPTER_INFO], [qw(IP_ADAPTER_INFO)]);
  }
  else
  {
    printf "GetAdaptersInfo() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Remarks>

The GetAdaptersInfo and GetInterfaceInfo functions do not return information about the loopback interface

Windows XP/Windows .NET Server 2003 family or later:  The list of adapters returned by GetAdaptersInfo includes unidirectional adapters.
To generate a list of adapters that can both send and receive data, call I<GetUniDirectionalAdapterInfo>, and exclude the returned adapters from the list returned by GetAdaptersInfo.

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional, Windows Me, Windows 98.
Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Iphlpapi.h.
Library: Iphlpapi.dll.


=head2 GetAdapterIndex(\$AdapterName,\$IfIndex)

The GetAdapterIndex function obtains the index of an adapter, given its name.

B<Example>

  use Win32::IPHelper;

  my $IfIndex;

  # the value for AdapterName is found in @IP_ADAPTER_INFO, for example
  # $IP_ADAPTER_INFO[0]{'AdapterName'};
  my $AdapterName = '{88CE272F-847A-40CF-BFBA-001D9AD97450}';

  $ret = Win32::IPHelper::GetAdapterIndex(\$AdapterName,\$IfIndex);

  if($ret == 0)
  {
    printf "Index for '%s' interface is %u\n", $AdapterName, $IfIndex;
  }
  else
  {
    printf "GetAdapterIndex() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional.
Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Iphlpapi.h.
Library: Iphlpapi.dll.


=head2 GetIfEntry($IfIndex,\%MIB_IFROW)

The GetIfEntry function retrieves a MIB_IFROW structure information for the specified interface on the local computer.

B<Example>

  use Win32::IPHelper;
  use Data::Dumper;

  my $IfIndex;

  # the value for AdapterName is found in @IP_ADAPTER_INFO, for example
  # $IP_ADAPTER_INFO[0]{'AdapterName'};
  my $AdapterName = '{88CE272F-847A-40CF-BFBA-001D9AD97450}';

  $ret = Win32::IPHelper::GetAdapterIndex(\$AdapterName,\$IfIndex);

  if($ret == 0)
  {
    my %MIB_IFROW;
    $ret = Win32::IPHelper::GetIfEntry($IfIndex,\%MIB_IFROW);

    if($ret == 0)
	{
      print Data::Dumper->Dump([\%MIB_IFROW], [qw(MIB_IFROW)]);
    }
    else
    {
      printf "GetIfEntry() error %u: %s\n", $ret, Win32::FormatMessage($ret);
    }
  }
  else
  {
    printf "GetAdapterIndex() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional, Windows NT Workstation 4.0 SP4 and later, Windows Me, Windows 98.
Server: Included in Windows .NET Server 2003, Windows 2000 Server, Windows NT Server 4.0 SP4 and later.
Header: Declared in Iphlpapi.h.
Library: Iphlpapi.dll.


=head2 AddIPAddress($Address,$IpMask,$IfIndex,\$NTEContext,\$NTEInstance)

The AddIPAddress function adds the specified IP address to the specified adapter.

B<Example>

  use Win32::IPHelper;

  my $IfIndex;

  # the value for AdapterName is found in @IP_ADAPTER_INFO, for example
  # $IP_ADAPTER_INFO[0]{'AdapterName'};
  my $AdapterName = '{88CE272F-847A-40CF-BFBA-001D9AD97450}';

  $ret = Win32::IPHelper::GetAdapterIndex(\$AdapterName,\$IfIndex);

  if($ret == 0)
  {
    my $Address = '192.168.1.10';
    my $IpMask = '255.255.255.0';
    my $NTEContext;
    my $NTEInstance;
    $ret = Win32::IPHelper::AddIPAddress($Address,$IpMask,$IfIndex,\$NTEContext,\$NTEInstance);

    if($ret == 0)
	{
      printf "Address has been added successfully with Context=%u\n", $NTEContext;
    }
    else
    {
      printf "AddIPAddress() error %u: %s\n", $ret, Win32::FormatMessage($ret);
    }
  }
  else
  {
    printf "GetAdapterIndex() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Remarks>

The IP address created by I<AddIPAddress> is not persistent.
The address exists only as long as the adapter object exists.
Restarting the computer destroys the address, as does manually resetting the network interface card (NIC).
Also, certain PnP events may destroy the address.

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional.
Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Iphlpapi.h.
Library: Iphlpapi.dll.


=head2 DeleteIPAddress($NTEContext)

The DeleteIPAddress function deletes an IP address previously added using I<AddIPAddress>.

B<Example>

  use Win32::IPHelper;

  my $NTEContext = 2;
  $ret = Win32::IPHelper::DeleteIPAddress($NTEContext);

  if($ret == 0)
  {
    printf "Address has been deleted successfully from Context=%u\n", $NTEContext;
  }
  else
  {
    printf "DeleteIPAddress() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional.
Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Iphlpapi.h.
Library: Iphlpapi.dll.


=head2 IpReleaseAddress(\%AdapterInfo)

The IpReleaseAddress function releases an IP address previously obtained through Dynamic Host Configuration Protocol (DHCP).

B<Example>

  use Win32::IPHelper;

  my %IP_INTERFACE_INFO;
  $ret = Win32::IPHelper::GetInterfaceInfo(\%IP_INTERFACE_INFO);

  if($ret == 0)
  {
    my %AdapterInfo = %{ $IP_INTERFACE_INFO{'Adapters'}[0] };
 
    $ret = Win32::IPHelper::IpReleaseAddress(\%AdapterInfo);

    if($ret == 0)
    {
      print "Address has been released successfully\n";
    }
	else
    {
      printf "IpReleaseAddress() error %u: %s\n", $ret, Win32::FormatMessage($ret);
    }
  }
  else
  {
    printf "GetInterfaceInfo() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional, Windows Me, Windows 98.
Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Iphlpapi.h.
Library: Iphlpapi.dll.


=head2 IpRenewAddress(\%AdapterInfo)

The IpRenewAddress function renews a lease on an IP address previously obtained through Dynamic Host Configuration Protocol (DHCP).

B<Example>

  use Win32::IPHelper;

  my %IP_INTERFACE_INFO;
  $ret = Win32::IPHelper::GetInterfaceInfo(\%IP_INTERFACE_INFO);

  if($ret == 0)
  {
    my %AdapterInfo = %{ $IP_INTERFACE_INFO{'Adapters'}[0] };
 
    $ret = Win32::IPHelper::IpRenewAddress(\%AdapterInfo);

    if($ret == 0)
    {
      print "Address has been renewed successfully\n";
    }
	else
    {
      printf "IpRenewAddress() error %u: %s\n", $ret, Win32::FormatMessage($ret);
    }
  }
  else
  {
    printf "GetInterfaceInfo() error %u: %s\n", $ret, Win32::FormatMessage($ret);
  }

B<Return Values>

If the function succeeds, the return value is 0.

If the function fails, the error code can be decoded with Win32::FormatMessage($ret).

B<Requirements>

Client: Included in Windows XP, Windows 2000 Professional, Windows Me, Windows 98.
Server: Included in Windows .NET Server 2003, Windows 2000 Server.
Header: Declared in Iphlpapi.h.
Library: Iphlpapi.dll.

=head1 CREDITS 

Thanks to Aldo Calpini for the powerful Win32::API module that makes this thing work.

=head1 AUTHOR

Luigino Masarati, E<lt>lmasarati@hotmail.comE<gt>

=cut

