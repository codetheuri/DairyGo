package member

import "strings"

// auditEntityMember is the entity_type of farmer audit entries.
const auditEntityMember = "member"

// setOptional applies an optional field from an update request: nil leaves
// it unchanged, blank clears it, anything else is stored trimmed.
func setOptional(field **string, value *string) {
	if value == nil {
		return
	}
	v := strings.TrimSpace(*value)
	if v == "" {
		*field = nil
		return
	}
	*field = &v
}

// auditFields are the farmer details kept in the audit trail when edited.
func auditFields(m *Member) map[string]string {
	deref := func(p *string) string {
		if p == nil {
			return ""
		}
		return *p
	}
	return map[string]string{
		"first_name":               m.FirstName,
		"last_name":                m.LastName,
		"phone":                    m.Phone,
		"national_id":              deref(m.NationalID),
		"email":                    deref(m.Email),
		"gender":                   deref(m.Gender),
		"location":                 deref(m.Location),
		"mpesa_number":             deref(m.MpesaNumber),
		"mpesa_name":               deref(m.MpesaName),
		"bank_name":                deref(m.BankName),
		"bank_account_number":      deref(m.BankAccountNumber),
		"bank_branch":              deref(m.BankBranch),
		"next_of_kin_name":         deref(m.NextOfKinName),
		"next_of_kin_relationship": deref(m.NextOfKinRelationship),
		"next_of_kin_phone":        deref(m.NextOfKinPhone),
	}
}

// diffFields returns the old and new values of the fields that differ.
func diffFields(before, after map[string]string) (old, changed map[string]string) {
	old, changed = map[string]string{}, map[string]string{}
	for k, v := range after {
		if before[k] != v {
			old[k], changed[k] = before[k], v
		}
	}
	return old, changed
}
