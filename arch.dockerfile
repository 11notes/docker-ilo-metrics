# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID= \
      APP_GID= \
      APP_GO_VERSION=0

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:localhealth AS distroless-localhealth


# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: ENTRYPOINT
  FROM 11notes/go:${APP_GO_VERSION} AS entrypoint
  COPY ./build /

  RUN set -ex; \
    cd /go/entrypoint; \
    eleven go build entrypoint main.go; \
    eleven distroless entrypoint;


# :: ILO EXPORTER
  FROM 11notes/go:${APP_GO_VERSION} AS build
  ARG APP_VERSION \
      BUILD_SRC=MauveSoftware/ilo_exporter.git \
      BUILD_ROOT=/go/ilo_exporter \
      BUILD_BIN=/ilo-metrics

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} ${APP_VERSION};

  RUN set -ex; \
    # quiet down the log and do not process anything from health check
    sed -i 's|c.debug = true|c.debug = false|g' ${BUILD_ROOT}/pkg/client/api_client.go; \
    sed -i 's|logrus.Infof("GET %s", uri)||g' ${BUILD_ROOT}/pkg/client/api_client.go; \
    sed -i 's|host := r.URL.Query().Get("host")|if r.Method == "HEAD" { return nil }; host := r.URL.Query().Get("host")|g' ${BUILD_ROOT}/main.go;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    eleven go build ${BUILD_BIN} .;

  RUN set -ex; \
    eleven distroless ${BUILD_BIN};


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM alpine

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-localhealth / /
    COPY --from=build /distroless/ /
    COPY --from=entrypoint /distroless/ /

# :: MONITORING
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:9090/metrics", "-I"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/entrypoint"]