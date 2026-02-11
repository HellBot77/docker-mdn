FROM alpine/git AS base

ARG TAG=latest
RUN git clone https://github.com/mdn/content.git && \
    cd content && \
    ([[ "$TAG" = "latest" ]] || git checkout ${TAG}) && \
    # rm -rf .git && \
    sed -i 's/FRED_WRITER_MODE=true/FRED_WRITER_MODE=false/' package.json && \
    git clone https://github.com/mdn/translated-content.git && \
    mv translated-content/files translated-files && \
    rm -rf translated-content

FROM node AS build

WORKDIR /content
COPY --from=base /git/content .
RUN npm ci && \
    CONTENT_TRANSLATED_ROOT=translated-files npm run build && \
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
COPY --from=build /content/translated-files ./translated-files

EXPOSE 5042 5043
ENV CONTENT_TRANSLATED_ROOT=translated-files
ENV NODE_ENV=production
CMD [ "npm", "start" ]
