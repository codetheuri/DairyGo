package customer

import "github.com/codetheuri/tusk/pkg/authz"

// Customer module permission constants. Grants for the Sacco roles are in
// migration 00011.
const (
	PermCustomersRead          = "customers.read"
	PermCustomersCreate        = "customers.create"
	PermCustomersUpdate        = "customers.update"
	PermCustomerPaymentsManage = "customers.payments.manage"
	PermCustomerStatementRead  = "customers.statement.read"
)

// Permissions exported by the customer module.
var Permissions = []authz.Permission{
	{Name: PermCustomersRead, Description: "Allows viewing customers (coolers, processors, hotels, buyers)"},
	{Name: PermCustomersCreate, Description: "Allows adding new customers, e.g. while recording a sale"},
	{Name: PermCustomersUpdate, Description: "Allows editing and deactivating customers"},
	{Name: PermCustomerPaymentsManage, Description: "Allows recording and voiding customer payments"},
	{Name: PermCustomerStatementRead, Description: "Allows viewing customer statements and outstanding balances"},
}

// init registers the module's permissions automatically into the default registry.
func init() {
	authz.Register(Permissions...)
}
