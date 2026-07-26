package collection

import "github.com/codetheuri/tusk/pkg/authz"

// Milk domain permission constants.
const (
	PermMilkPricesRead          = "milk.prices.read"
	PermMilkPricesManage        = "milk.prices.manage"
	PermMilkCollectionsRead     = "milk.collections.read"
	PermMilkCollectionsCreate   = "milk.collections.create"
	PermMilkCollectionsManage   = "milk.collections.manage"
	PermMilkSalesRead           = "milk.sales.read"
	PermMilkSalesCreate         = "milk.sales.create"
	PermMilkSalesManage         = "milk.sales.manage"
	PermMilkSpoilageRead        = "milk.spoilage.read"
	PermMilkSpoilageCreate      = "milk.spoilage.create"
	PermMilkReconciliationRead  = "milk.reconciliation.read"
)

// Permissions exported by the collection module.
var Permissions = []authz.Permission{
	{
		Name:        PermMilkPricesRead,
		Description: "Allows viewing current and historical milk buying prices",
	},
	{
		Name:        PermMilkPricesManage,
		Description: "Allows setting new milk buying prices",
	},
	{
		Name:        PermMilkCollectionsRead,
		Description: "Allows viewing milk collection entries",
	},
	{
		Name:        PermMilkCollectionsCreate,
		Description: "Allows recording daily milk collections from farmers",
	},
	{
		Name:        PermMilkCollectionsManage,
		Description: "Allows verifying, rejecting, or adjusting milk collection entries",
	},
	{
		Name:        PermMilkSalesRead,
		Description: "Allows viewing direct milk sales records",
	},
	{
		Name:        PermMilkSalesCreate,
		Description: "Allows recording direct field sales to buyers/hotels",
	},
	{
		Name:        PermMilkSalesManage,
		Description: "Allows managing direct milk sales records",
	},
	{
		Name:        PermMilkSpoilageRead,
		Description: "Allows viewing milk spoilage/loss logs",
	},
	{
		Name:        PermMilkSpoilageCreate,
		Description: "Allows logging milk spoilage/loss events",
	},
	{
		Name:        PermMilkReconciliationRead,
		Description: "Allows viewing collector daily milk reconciliation summaries",
	},
}

// init registers the module's permissions automatically into the default registry.
func init() {
	authz.Register(Permissions...)
}
