package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/codetheuri/tusk/config"
	"github.com/codetheuri/tusk/internal/memberimport"
	appDatabase "github.com/codetheuri/tusk/internal/platform/database"
	"github.com/codetheuri/tusk/pkg/logger"
	gormlogger "gorm.io/gorm/logger"
)

const membersImportUsage = `Usage: dairy-cli members import --sacco <code or id> --file <farmers.csv> [--replace --confirm <code>] [--dry-run]

Loads a Sacco's farmer register. The CSV needs the columns
membership_number, name, gender (M/F), phone (may be blank), status (ACTIVE/INACTIVE).

  --replace   first delete the Sacco's farmers, collections, sales, spoilage,
              transfers, customers and their payments, and their history.
              Staff, settings and milk prices are kept. Needs --confirm with
              the Sacco's code, to be sure of the Sacco.
  --dry-run   show what would happen, change nothing.

Everything happens in one transaction: all of it, or nothing.`

func handleMembersCommand(args []string) {
	if len(args) < 1 || args[0] != "import" {
		fmt.Println(membersImportUsage)
		os.Exit(1)
	}
	cmd := flag.NewFlagSet("members import", flag.ExitOnError)
	cmd.Usage = func() { fmt.Println(membersImportUsage) }
	saccoArg := cmd.String("sacco", "", "Sacco code or id")
	file := cmd.String("file", "", "CSV file of farmers")
	replace := cmd.Bool("replace", false, "clear the Sacco's farmers and milk records first")
	confirm := cmd.String("confirm", "", "the Sacco's code, required with --replace")
	dryRun := cmd.Bool("dry-run", false, "report only; change nothing")
	_ = cmd.Parse(args[1:])
	if *saccoArg == "" || *file == "" {
		cmd.Usage()
		os.Exit(1)
	}

	f, err := os.Open(*file)
	if err != nil {
		fail("cannot open the file: %v", err)
	}
	rows, problems, warnings := memberimport.Parse(f)
	_ = f.Close()
	for _, w := range warnings {
		fmt.Println("warning:", w)
	}
	if len(problems) > 0 {
		for _, p := range problems {
			fmt.Println("problem:", p)
		}
		fail("fix the file and run again; nothing was changed")
	}

	log := logger.NewConsoleLogger()
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatal("Failed to load configuration", err)
	}
	db, err := appDatabase.NewGoRMDB(cfg, log)
	if err != nil {
		log.Fatal("Failed to connect to database", err)
	}
	db.Logger = gormlogger.Default.LogMode(gormlogger.Silent)

	var sacco struct{ ID, Code, Name string }
	err = db.Table("saccos").Select("id, code, name").
		Where("deleted_at IS NULL AND (id = ? OR LOWER(code) = LOWER(?))", *saccoArg, *saccoArg).
		Take(&sacco).Error
	if err != nil {
		fail("no Sacco with code or id %q", *saccoArg)
	}
	fmt.Printf("Sacco: %s (code %s, id %s)\n", sacco.Name, sacco.Code, sacco.ID)
	if *replace && !*dryRun && !strings.EqualFold(*confirm, sacco.Code) {
		fail("--replace deletes this Sacco's records: add --confirm %s to go ahead", sacco.Code)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()
	report, err := memberimport.Import(ctx, db, memberimport.Options{
		SaccoID: sacco.ID,
		Rows:    rows,
		Replace: *replace,
		DryRun:  *dryRun,
		Source:  filepath.Base(*file),
	})
	if err != nil {
		fail("import failed, nothing was changed: %v", err)
	}

	if *dryRun {
		fmt.Println("\nDRY RUN: this is what would happen. Nothing was changed.")
	}
	if *replace {
		fmt.Println("\nDeleted:")
		for _, c := range report.Cleared {
			fmt.Printf("  %-18s %d\n", c.Table, c.Rows)
		}
	}
	fmt.Printf("\nFarmers added: %d (%d active, %d inactive; %d without a phone)\n",
		report.Added, report.Active, report.Inactive, report.NoPhone)
}

func fail(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "error: "+format+"\n", args...)
	os.Exit(1)
}
