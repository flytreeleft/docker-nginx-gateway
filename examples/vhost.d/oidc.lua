-- https://github.com/pingidentity/lua-resty-openidc#sample-configuration-for-google-signin

if ngx.var.oidc_ip_whitelist and ngx.var.remote_addr then
    for ip in string.gmatch(ngx.var.oidc_ip_whitelist, '([^, ]+)') do
        if ip == ngx.var.remote_addr then
            return
        end
    end
end

local opts = {
    -- Redirect uri which doesn't exist and cannot be '/'
    redirect_uri_path = "/redirect_uri",
    -- TODO Change the discovery URL as yours.
    discovery = "https://sso.example.com/auth/realms/"..ngx.var.oidc_realm.."/.well-known/openid-configuration",
    client_id = ngx.var.oidc_client_id,
    --client_secret = ngx.var.oidc_client_secret,
    ssl_verify = "no",
    -- To prevent 'client_secret' is nil:
    -- https://github.com/pingidentity/lua-resty-openidc/blob/v1.3.2/lib/resty/openidc.lua#L226
    token_endpoint_auth_method = "client_secret_post",
    --refresh_session_interval = 900,
    --access_token_expires_in = 3600,
    --force_reauthorize = false
}

-- Set a fixed and unique session secret for every domain to prevent infinite redirect loop
--   https://github.com/pingidentity/lua-resty-openidc/issues/32#issuecomment-273900768
--   https://github.com/openresty/lua-nginx-module#set_by_lua
local session_opts = {
    secret = ngx.encode_base64(ngx.var.server_name):sub(0, 32)
}
local res, err = require("resty.openidc").authenticate(opts, nil, nil, session_opts)

if err then
    ngx.status = 500
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- https://kubernetes.io/docs/admin/authentication/#authenticating-proxy
if res.id_token.sub then
    ngx.req.set_header("X-Remote-User", res.id_token.username)

    if res.id_token.groups then
        for i, group in ipairs(res.id_token.groups) do
            ngx.req.set_header("X-Remote-Group", group)
        end
    end
else
    ngx.req.clear_header("X-Remote-USER")
    ngx.req.clear_header("X-Remote-GROUP")
end
