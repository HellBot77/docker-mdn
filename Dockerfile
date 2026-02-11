FROM alpine/git AS base

ARG TAG=latest
RUN git clone https://github.com/mdn/content.git && \
    cd content && \
    ([[ "$TAG" = "latest" ]] || git checkout ${TAG}) && \
    # rm -rf .git && \
    sed -i 's/FRED_WRITER_MODE=true/FRED_WRITER_MODE=false/' package.json

FROM node AS build

WORKDIR /
RUN git clone https://github.com/mdn/translated-content.git && \
    # git clone https://github.com/mdn/blog.git && \
    git clone https://github.com/mdn/curriculum.git && \
    git clone https://github.com/mdn/mdn-contributor-spotlight.git && \
    git clone https://github.com/mdn/generic-content.git

WORKDIR /content
COPY --from=base /git/content .
RUN npm ci && \
    CONTENT_TRANSLATED_ROOT=/translated-content/files \
    # BLOG_ROOT=/blog/content/posts \
    CURRICULUM_ROOT=/curriculum \
    CONTRIBUTOR_SPOTLIGHT_ROOT=/mdn-contributor-spotlight/contributors \
    GENERIC_CONTENT_ROOT=/generic-content/files \
    npm run build && \
    rm -rf node_modules && \
    npm ci --omit=dev

FROM node

COPY --from=build /translated-content/.git /translated-content/.git
COPY --from=build /translated-content/files /translated-content/files
# COPY --from=build /blog/content/posts /blog/content/posts
COPY --from=build /curriculum /curriculum
COPY --from=build /mdn-contributor-spotlight/contributors /mdn-contributor-spotlight/contributors
COPY --from=build /generic-content/files /generic-content/files

WORKDIR /content
COPY --from=build /content/package.json ./
COPY --from=build /content/node_modules ./node_modules
COPY --from=build /content/build ./build

COPY --from=build /content/.git ./.git
COPY --from=build /content/files ./files
COPY --from=build /content/scripts/up-to-date-check.js ./scripts/

ENV CONTENT_TRANSLATED_ROOT=/translated-content/files
# ENV BLOG_ROOT=/blog/content/posts
ENV CURRICULUM_ROOT=/curriculum
ENV CONTRIBUTOR_SPOTLIGHT_ROOT=/mdn-contributor-spotlight/contributors
ENV GENERIC_CONTENT_ROOT=/generic-content/files

ENV RUMBA_URL=https://developer.mozilla.org
ENV CF_URL=https://developer.mozilla.org
ENV FRED_BCD_BASE_URL=https://bcd.developer.mozilla.org
ENV FRED_OBSERVATORY_API_URL=https://observatory-api.mdn.mozilla.net

EXPOSE 5042 5043
ENV NODE_ENV=production
CMD [ "npm", "start" ]
