export default function AccessDeniedPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-6">
      <div className="w-full max-w-md rounded-2xl bg-white p-8 text-center shadow-sm">
        <h1 className="text-2xl font-semibold text-gray-900">Access Denied</h1>
        <p className="mt-3 text-sm text-gray-600">
          Your account does not have permission to access the TrustCare admin
          panel.
        </p>
      </div>
    </div>
  );
}
