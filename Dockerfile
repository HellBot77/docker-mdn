FROM alpine/git AS base

ARG TAG=latest
RUN git clone https://github.com/mdn/content.git && \
    cd content && \
    ([[ "$TAG" = "latest" ]] || git checkout ${TAG}) && \
    # rm -rf .git && \
    sed -i 's/FRED_WRITER_MODE=true/FRED_WRITER_MODE=false/' package.json

FROM node AS build

WORKDIR /content
COPY --from=base /git/content .
RUN npm ci && \
    npm run build && \
    rm -rf node_modules && \
    npm ci --omit=dev

FROM node

WORKDIR /content
COPY --from=build /content/package.json ./
COPY --from=build /content/node_modules ./node_modules
COPY --from=build /content/build ./build

COPY --from=build /content/.git ./.git
COPY --from=build /content/files ./files
COPY --from=build /content/scripts/up-to-date-check.js ./scripts/

EXPOSE 5042
ENV NODE_ENV=production
CMD [ "npm", "start" ]
