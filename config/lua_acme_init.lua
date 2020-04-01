function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end
function read_domains(file)
    if not file_exists(file) then return {} end
    lines = {}
    for line in io.lines(file) do
      lines[#lines + 1] = line
    end
    return lines
end

require("resty.acme.autossl").init({
    tos_accepted = true,
    staging = os.getenv("CERT_STAGING") == "true",
    domain_key_types = { 'rsa' },
    enabled_challenge_handlers = { 'http-01', 'tls-alpn-01' },
    account_key_path = "/etc/nginx/ssl/acme/account.key",
    account_email = os.getenv("CERT_EMAIL"),
    domain_whitelist = read_domains("/etc/letsencrypt/domains.txt"),
    storage_adapter = "file",
    storage_config = {
        dir = '/etc/letsencrypt',
    },
})

require("resty.acme.autossl").init_worker()
