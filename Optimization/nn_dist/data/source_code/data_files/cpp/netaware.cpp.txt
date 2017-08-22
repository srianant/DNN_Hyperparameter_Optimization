#include <winsock2.h>
#include <Iphlpapi.h>
#pragma comment(lib, "IPHLPAPI.lib")
#include <windows.h>
#include <Wininet.h>
#pragma comment(lib, "Wininet.lib") 
#include <stdio.h>
#include <atlbase.h>
#pragma comment(lib, "wsock32.lib")
#pragma comment(lib, "ws2_32.lib")
#include <assert.h>
#include <memory>
#include<Netlistmgr.h>


typedef enum {
	UNKNOWN,
	YES,
	NO
}INTERNET_STATE;


void print_connection_type(INTERNET_STATE state) {
	switch(state) {
		case YES:
			printf("internet connection exists.\n");
			break;
		case NO:
			printf("No internet connection.\n");
			break;
		case UNKNOWN:
			printf("unknown connection.\n");
			break;
	}
}

BOOL IsWindowsXPorLater() {
	OSVERSIONINFO osvi;
	ZeroMemory(&osvi, sizeof(OSVERSIONINFO));
	osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	GetVersionEx(&osvi);
	return (( (osvi.dwMajorVersion > 5) || ( (osvi.dwMajorVersion == 5) && (osvi.dwMinorVersion >= 1) )));
}

void
wait_for_connection_type_change_with_winsock() {
	printf("\n"__FUNCTION__"\n");
	WSAQUERYSET querySet = {0};
	querySet.dwSize = sizeof(WSAQUERYSET);
	querySet.dwNameSpace = NS_NLA;

	HANDLE LookupHandle = NULL;
	WSALookupServiceBegin(&querySet, LUP_RETURN_ALL, &LookupHandle);
	DWORD BytesReturned = 0;
	WSANSPIoctl(LookupHandle, SIO_NSP_NOTIFY_CHANGE, NULL, 0, NULL, 0, &BytesReturned, NULL);
	WSALookupServiceEnd(LookupHandle);
}

INTERNET_STATE
connection_type_with_winsock()
{
	typedef enum _NLA_BLOB_DATA_TYPE {
		NLA_RAW_DATA          = 0,
		NLA_INTERFACE         = 1,
		NLA_802_1X_LOCATION   = 2,
		NLA_CONNECTIVITY      = 3,
		NLA_ICS               = 4,
	}NLA_BLOB_DATA_TYPE;

	typedef enum _NLA_CONNECTIVITY_TYPE {
		NLA_NETWORK_AD_HOC    = 0,
		NLA_NETWORK_MANAGED   = 1,
		NLA_NETWORK_UNMANAGED = 2,
		NLA_NETWORK_UNKNOWN   = 3,
	}NLA_CONNECTIVITY_TYPE;

	typedef enum _NLA_INTERNET {
		NLA_INTERNET_UNKNOWN  = 0,
		NLA_INTERNET_NO       = 1,
		NLA_INTERNET_YES      = 2,
	}NLA_INTERNET;
	typedef struct _NLA_BLOB {
		struct {
			NLA_BLOB_DATA_TYPE type;
			DWORD dwSize;
			DWORD nextOffset;
		} header;
		union {
			// header.type -> NLA_RAW_DATA
			CHAR rawData[1];
			// header.type -> NLA_INTERFACE
			struct {
				DWORD dwType;
				DWORD dwSpeed;
				CHAR adapterName[1];
			} interfaceData;
			// header.type -> NLA_802_1X_LOCATION
			struct {
				CHAR information[1];
			} locationData;
			// header.type -> NLA_CONNECTIVITY
			struct {
				NLA_CONNECTIVITY_TYPE type;
				NLA_INTERNET internet;
			} connectivity;
			// header.type -> NLA_ICS
			struct {
				struct {
					DWORD speed;
					DWORD type;
					DWORD state;
					WCHAR machineName[256];
					WCHAR sharedAdapterName[256];
				} remote;
			} ICS;
		} data;
	}NLA_BLOB;

	printf("\n"__FUNCTION__":");
	HANDLE ws_handle;
	WSAData data = {0};
	WSAQUERYSET query_set = {0};
	query_set.dwSize = sizeof(WSAQUERYSET);
	query_set.dwNameSpace = NS_NLA;

	if (0 != WSALookupServiceBegin(&query_set, LUP_RETURN_BLOB,&ws_handle)) {
			return UNKNOWN;
	}

	DWORD length = 0;
	int result = 
		WSALookupServiceNext(ws_handle,LUP_RETURN_BLOB, &length, NULL);
	if (result != 0) {
		result = WSAGetLastError();
		if (result == WSAEFAULT) {
			return UNKNOWN;
		} else if (result == WSA_E_NO_MORE || result == WSAENOMORE) {
			return NO;
		} else {
			return UNKNOWN;
		}
	}
	std::auto_ptr<char> result_buffer(new char[length]);
	memset(result_buffer.get(), 0, length);
	reinterpret_cast<WSAQUERYSET*>(result_buffer.get())->dwSize = sizeof(WSAQUERYSET);
	do {
		result = WSALookupServiceNext(ws_handle,LUP_RETURN_BLOB, &length, reinterpret_cast<WSAQUERYSET*>(result_buffer.get()));

		if (result == 0) {
			WSAQUERYSET* query_set = reinterpret_cast<WSAQUERYSET*>(result_buffer.get());
			BLOB* blob = reinterpret_cast<BLOB*>(query_set->lpBlob);
			NLA_BLOB* nla_blob = reinterpret_cast<NLA_BLOB*>(blob->pBlobData);
			if (nla_blob->header.type == NLA_CONNECTIVITY) {
				NLA_CONNECTIVITY_TYPE t = nla_blob->data.connectivity.type;
				NLA_INTERNET i = nla_blob->data.connectivity.internet;
				if (i == NLA_INTERNET_YES) {
					return YES;
				}
			}
			else {
				continue;

			}
		} else {
			result = WSAGetLastError();

			if (result == WSAEFAULT) {
				return UNKNOWN;
			} else if (result == WSA_E_NO_MORE || result == WSAENOMORE) {
				// There was nothing to iterate over!
			} else {
				return UNKNOWN;
			}
		}
	}while(result == 0);

	result = WSALookupServiceEnd(ws_handle);

	return NO;


} 

INTERNET_STATE
connection_type_with_iphlp()
{
	printf("\n"__FUNCTION__":");
	// Assume that we're online until proven otherwise.

	DWORD size = 0;

	if (GetAdaptersAddresses(AF_UNSPEC, 0, 0, 0, &size) != ERROR_BUFFER_OVERFLOW)
		return UNKNOWN;

	IP_ADAPTER_ADDRESSES* addresses = (IP_ADAPTER_ADDRESSES*)malloc(size);

	if (GetAdaptersAddresses(AF_UNSPEC, 0, 0, addresses, &size) != ERROR_SUCCESS) {
		// We couldn't determine whether we're online or not, so assume that we are.
		return UNKNOWN;
	}

	PIP_ADAPTER_ADDRESSES pCurrAddresses = addresses;
	for (;pCurrAddresses != NULL;pCurrAddresses = pCurrAddresses->Next) {
		if (pCurrAddresses->IfType == MIB_IF_TYPE_LOOPBACK) 
			continue;

		if (pCurrAddresses->OperStatus != IfOperStatusUp)
			continue;

		// We found an interface that was up.
		return YES;
	}

	// We didn't find any valid interfaces, so we must be offline.
	return NO;
}

INTERNET_STATE 
connection_type_with_wininet() {
	printf("\n"__FUNCTION__":");
	DWORD state = 0;
	HMODULE winnet = LoadLibraryA("wininet.dll");
	if (winnet == NULL) {
		printf("Error:%d\n", GetLastError());
		return UNKNOWN;
	}
	typedef BOOL (WINAPI *NET_CONNECTED_STATE)(LPDWORD lpdwFlags, DWORD dwReserved);
	NET_CONNECTED_STATE net_connected_state = (NET_CONNECTED_STATE)GetProcAddress(winnet, "InternetGetConnectedState");
	if (net_connected_state == NULL) {
		printf("Error:%d\n", GetLastError());
		return UNKNOWN;
	}

	return net_connected_state(&state, 0) ? YES : NO;
}

INTERNET_STATE 
connection_type_with_nlm() {
	printf("\n"__FUNCTION__":");
	if (!IsWindowsXPorLater()) {
		return UNKNOWN;
	}
	IUnknown* unknown = NULL;
	HRESULT r = CoCreateInstance(CLSID_NetworkListManager, NULL, CLSCTX_ALL, IID_IUnknown, (void **)&unknown);
	if (SUCCEEDED(r))
	{
		INetworkListManager* nlm = NULL;
		r = unknown->QueryInterface(IID_INetworkListManager, (void **)&nlm);
		if (SUCCEEDED(r))
		{
			VARIANT_BOOL t = VARIANT_FALSE;
			r = nlm->get_IsConnectedToInternet(&t);
			if (SUCCEEDED(r))
			{
				return t == VARIANT_TRUE ? YES : NO;
			}
		}
	}
	return NO;
}

void 
connection_type_with_nlm_event() {
	class CNetworkListManagerEvent : public INetworkListManagerEvents
	{
	public:
		CNetworkListManagerEvent()
		{

		}

		~CNetworkListManagerEvent()
		{

		}

		HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void **ppvObject)
		{
			HRESULT Result = S_OK;
			if (IsEqualIID(riid, IID_IUnknown))
			{
				*ppvObject = (IUnknown *)this;
			}
			else if (IsEqualIID(riid ,IID_INetworkListManagerEvents))
			{
				*ppvObject = (INetworkListManagerEvents *)this;
			}
			else
			{
				Result = E_NOINTERFACE;
			}

			return Result;
		}

		ULONG STDMETHODCALLTYPE AddRef()
		{
			return 1;
		}

		ULONG STDMETHODCALLTYPE Release()
		{
			return 1;
		}

		virtual HRESULT STDMETHODCALLTYPE ConnectivityChanged(
			/* [in] */ NLM_CONNECTIVITY newConnectivity)
		{
			printf("\n"__FUNCTION__":");
			if (NLM_CONNECTIVITY_IPV4_INTERNET & newConnectivity 
				|| NLM_CONNECTIVITY_IPV6_INTERNET & newConnectivity)
			{
				print_connection_type(YES);
			}
			else
			{
				print_connection_type(NO);
			}
			
			return S_OK;
		}
	};

	CComPtr<IUnknown> unknown = NULL;
	HRESULT result = CoCreateInstance(CLSID_NetworkListManager, 
		NULL, CLSCTX_ALL, IID_IUnknown, (void **)&unknown);
	if (FAILED(result))
	{
		return;
	}
	CComPtr<INetworkListManager> nlm = NULL;
	result = 
		unknown->QueryInterface(IID_INetworkListManager, (void **)&nlm);
	if (FAILED(result))
	{
		return;
	}

 
	CComPtr<IConnectionPointContainer> container = NULL;
	result = nlm->QueryInterface(IID_IConnectionPointContainer,
		(void **)&container);

	if (FAILED(result))
	{
		return;
	}
	CComPtr<IConnectionPoint> connect_point = NULL;
	result = container->FindConnectionPoint(IID_INetworkListManagerEvents, 
		&connect_point);
	if (FAILED(result))
	{
		return;
	}
	DWORD Cookie = NULL;

	std::auto_ptr<CNetworkListManagerEvent> e(new CNetworkListManagerEvent);

	result = connect_point->Advise(reinterpret_cast<IUnknown *>(e.get()), &Cookie);
	if (FAILED(result))
	{
		return;
	}
	while(1) {
		Sleep(1);
	}

	connect_point->Unadvise(Cookie);
 
	return;
}

DWORD WINAPI loop(void* data) {
	INTERNET_STATE t = UNKNOWN;while(1) {
		print_connection_type(connection_type_with_wininet());
		print_connection_type(connection_type_with_iphlp());
		print_connection_type(connection_type_with_winsock());
		print_connection_type(connection_type_with_nlm());
		system("pause");
	}
	return 0;
}
DWORD WINAPI notify_with_nlm(void* data) {
	while(1) {
		connection_type_with_nlm_event();
	}
}

DWORD WINAPI notify_with_winsock(void* data) {
	while(1) {
		wait_for_connection_type_change_with_winsock();
		print_connection_type(connection_type_with_nlm());
	}
}
int main(int argv, char** argc)
{
	CoInitializeEx(NULL, COINIT_MULTITHREADED);
	
	WSAData data = {0};
	WSAStartup(MAKEWORD(2, 0), &data);
	
	DWORD id = 0;
	CloseHandle(CreateThread(NULL,0,notify_with_nlm,NULL, 0, &id));
	CloseHandle(CreateThread(NULL,0,notify_with_winsock,NULL, 0, &id));
	CloseHandle(CreateThread(NULL,0,loop,NULL, 0, &id));
	MSG msg;
	while(GetMessage(&msg,NULL, 0, 0) > 0) 
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg); 
	}
	
	WSACleanup();
	CoUninitialize();
	return 0;
}
