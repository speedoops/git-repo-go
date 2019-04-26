// Copyright © 2019 Alibaba Co. Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cmd

import (
	"code.alibaba-inc.com/force/git-repo/project"
	"code.alibaba-inc.com/force/git-repo/workspace"
	"github.com/jiangxin/multi-log"
	"github.com/spf13/cobra"
)

type startCommand struct {
	cmd *cobra.Command
	ws  *workspace.WorkSpace

	O struct {
		All bool
	}
}

func (v *startCommand) Command() *cobra.Command {
	if v.cmd != nil {
		return v.cmd
	}

	v.cmd = &cobra.Command{
		Use:   "start",
		Short: "Start a new branch for development",
		Long:  `Begin a new branch of development, starting from the revision specified in the manifest.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			return v.runE(args)
		},
	}
	v.cmd.Flags().BoolVar(&v.O.All,
		"all",
		false,
		"begin branch in all projects")

	return v.cmd
}

func (v *startCommand) WorkSpace() *workspace.WorkSpace {
	if v.ws == nil {
		v.reloadWorkSpace()
	}
	return v.ws
}

func (v *startCommand) reloadWorkSpace() {
	var err error
	v.ws, err = workspace.NewWorkSpace("")
	if err != nil {
		log.Fatal(err)
	}
}

func (v startCommand) runE(args []string) error {
	var (
		failed    = []string{}
		execError error
	)

	ws := v.WorkSpace()

	if len(args) == 0 {
		return newUserError("no args")
	}

	branch := args[0]

	names := []string{}
	if !v.O.All {
		if len(args) > 1 {
			names = append(names, args[1:]...)
		} else {
			// current project
			names = append(names, ".")
		}
	}

	allProjects, err := ws.GetProjects(nil, names...)
	if err != nil {
		return err
	}

	for _, p := range allProjects {
		merge := ""
		if project.IsImmutable(p.Revision) {
			if p.DestBranch != "" {
				merge = p.DestBranch
			} else {
				if ws.Manifest != nil &&
					ws.Manifest.Default != nil {
					merge = ws.Manifest.Default.Revision
				}
			}
		}
		err := p.StartBranch(branch, merge)
		if err != nil {
			failed = append(failed, p.Path)
			execError = err
		}
	}

	if execError != nil {
		for _, p := range failed {
			log.Errorf("cannot start branch '%s' for '%s'", branch, p)
		}
		return execError
	}
	return nil
}

var startCmd = startCommand{}

func init() {
	rootCmd.AddCommand(startCmd.Command())
}