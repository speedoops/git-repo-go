#!/bin/sh

test_description="git-repo helper remote-gerrit"

. ./lib/sharness.sh

cat >expect <<EOF
{
  "Cmd": "git",
  "Args": [
    "push",
    "--receive-pack=gerrit receive-pack",
    "ssh://git@example.com:29418/test/repo.git",
    "refs/heads/my/topic:refs/for/master%r=u1,r=u2,cc=u3,cc=u4"
  ],
  "Env": null,
  "GitConfig": null
}
EOF

test_expect_success "upload command (SSH protocol)" '
	cat <<-EOF |
	{
	  "Description": "description of code review",
	  "DestBranch": "master",
	  "Draft": false,
	  "Issue": "123",
	  "LocalBranch": "my/topic",
	  "People":[
	  	["u1", "u2"],
		["u3", "u4"]
	  ],
	  "ProjectName": "test/repo",
	  "ReviewURL": "ssh://git@example.com:29418",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
  	}	
	EOF
	git-repo helper remote-gerrit --upload >out 2>&1 &&
	cat out | jq . >actual &&
	test_cmp expect actual
'

cat >expect <<EOF
{
  "Cmd": "git",
  "Args": [
    "push",
    "--receive-pack=gerrit receive-pack",
    "ssh://git@example.com/test/repo.git",
    "refs/heads/my/topic:refs/drafts/master%r=u1,r=u2,cc=u3,cc=u4"
  ],
  "Env": null,
  "GitConfig": null
}
EOF

test_expect_success "upload command (SSH protocol, draft)" '
	cat <<-EOF |
	{
	  "Description": "description of code review",
	  "DestBranch": "master",
	  "Draft": true,
	  "Issue": "123",
	  "LocalBranch": "my/topic",
	  "People":[
	  	["u1", "u2"],
		["u3", "u4"]
	  ],
	  "ProjectName": "test/repo",
	  "ReviewURL": "ssh://git@example.com",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
  	}	
	EOF
	git-repo helper remote-gerrit --upload >out 2>&1 &&
	cat out | jq . >actual &&
	test_cmp expect actual
'

cat >expect <<EOF
{
  "Cmd": "git",
  "Args": [
    "push",
    "https://example.com/test/repo.git",
    "refs/heads/my/topic:refs/for/master%r=u1,r=u2,cc=u3,cc=u4"
  ],
  "Env": null,
  "GitConfig": null
}
EOF

test_expect_success "upload command (HTTP protocol)" '
	cat <<-EOF |
	{
	  "Description": "description of code review",
	  "DestBranch": "master",
	  "Draft": false,
	  "Issue": "123",
	  "LocalBranch": "my/topic",
	  "People":[
	  	["u1", "u2"],
		["u3", "u4"]
	  ],
	  "ProjectName": "test/repo",
	  "ReviewURL": "https://example.com",
	  "Title": "title of code review",
	  "UserEmail": "Jiang Xin <worldhello.net@gmail.com>",
	  "Version": 1
  	}	
	EOF
	git-repo helper remote-gerrit --upload >out 2>&1 &&
	cat out | jq . >actual &&
	test_cmp expect actual
'

cat >expect <<EOF
WARNING: Patch ID should not be 0, set it to 1
refs/changes/45/12345/1
EOF

test_expect_success "download ref" '
	printf "12345\n" | \
	git-repo helper remote-gerrit --download >actual 2>&1 &&
	test_cmp expect actual
'

cat >expect <<EOF
refs/changes/45/12345/2
EOF

test_expect_success "download ref" '
	printf "12345 2\n" | \
	git-repo helper remote-gerrit --download >actual 2>&1 &&
	test_cmp expect actual
'

test_done