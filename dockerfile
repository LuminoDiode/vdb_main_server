FROM alpine:3 AS base



FROM mcr.microsoft.com/dotnet/sdk:7.0-alpine AS build
COPY ./vdb_main_server_api /vdb_main_server_api
COPY ./DataAccessLayer /DataAccessLayer
COPY ./ServicesLayer /ServicesLayer
RUN dotnet publish /vdb_main_server_api/main_server_api.csproj -c "Release" -r linux-musl-x64 --no-self-contained -o /app/publish



FROM base AS final

RUN apk add -q --no-progress bash
RUN apk add -q --no-progress nginx
RUN apk add -q --no-progress openssl
RUN apk add -q --no-progress aspnetcore7-runtime
RUN mkdir -p /data/nginx/cache

COPY --from=build /app/publish /app
COPY ./build_alpine/pre-setup.sh ./etc/rest2wg/pre-setup.sh
COPY ./build_alpine/pre-nginx.conf/ ./etc/nginx/nginx.conf
COPY ./build_alpine/pre-nginx-ssl-params.conf ./etc/nginx/snippets/ssl-params.conf
COPY ./build_alpine/pre-nginx-self-signed.conf ./etc/nginx/snippets/self-signed.conf

ENV ASPNETCORE_ENVIRONMENT=Production
ENV VDB_GENERATE_JWT_SIG=true
ENV VDB_ALLOWED_IP='all'
CMD ["bash", "-c", "umask 077 && chmod +x /etc/rest2wg/pre-setup.sh && /etc/rest2wg/pre-setup.sh"]