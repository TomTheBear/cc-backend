// Copyright (C) 2022 NHR@FAU, University Erlangen-Nuremberg.
// All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.
package schema

import (
	"encoding/json"
	"time"
)

type LdapConfig struct {
	Url             string `json:"url"`
	UserBase        string `json:"user_base"`
	SearchDN        string `json:"search_dn"`
	UserBind        string `json:"user_bind"`
	UserFilter      string `json:"user_filter"`
	SyncInterval    string `json:"sync_interval"` // Parsed using time.ParseDuration.
	SyncDelOldUsers bool   `json:"sync_del_old_users"`
}

type JWTAuthConfig struct {
	// Specifies for how long a session or JWT shall be valid
	// as a string parsable by time.ParseDuration().
	MaxAge int64 `json:"max-age"`

	// Specifies which cookie should be checked for a JWT token (if no authorization header is present)
	CookieName string `json:"cookieName"`

	// Deny login for users not in database (but defined in JWT).
	// Ignore user roles defined in JWTs ('roles' claim), get them from db.
	ForceJWTValidationViaDatabase bool `json:"forceJWTValidationViaDatabase"`

	// Specifies which issuer should be accepted when validating external JWTs ('iss' claim)
	TrustedExternalIssuer string `json:"trustedExternalIssuer"`
}

type IntRange struct {
	From int `json:"from"`
	To   int `json:"to"`
}

type TimeRange struct {
	From *time.Time `json:"from"`
	To   *time.Time `json:"to"`
}

type FilterRanges struct {
	Duration  *IntRange  `json:"duration"`
	NumNodes  *IntRange  `json:"numNodes"`
	StartTime *TimeRange `json:"startTime"`
}

type ClusterConfig struct {
	Name                 string          `json:"name"`
	FilterRanges         *FilterRanges   `json:"filterRanges"`
	MetricDataRepository json.RawMessage `json:"metricDataRepository"`
}

// Format of the configuration (file). See below for the defaults.
type ProgramConfig struct {
	// Address where the http (or https) server will listen on (for example: 'localhost:80').
	Addr string `json:"addr"`

	// Drop root permissions once .env was read and the port was taken.
	User  string `json:"user"`
	Group string `json:"group"`

	// Disable authentication (for everything: API, Web-UI, ...)
	DisableAuthentication bool `json:"disable-authentication"`

	// If `embed-static-files` is true (default), the frontend files are directly
	// embeded into the go binary and expected to be in web/frontend. Only if
	// it is false the files in `static-files` are served instead.
	EmbedStaticFiles bool   `json:"embed-static-files"`
	StaticFiles      string `json:"static-files"`

	// 'sqlite3' or 'mysql' (mysql will work for mariadb as well)
	DBDriver string `json:"db-driver"`

	// For sqlite3 a filename, for mysql a DSN in this format: https://github.com/go-sql-driver/mysql#dsn-data-source-name (Without query parameters!).
	DB string `json:"db"`

	// Config for job archive
	Archive json.RawMessage `json:"archive"`

	// Keep all metric data in the metric data repositories,
	// do not write to the job-archive.
	DisableArchive bool `json:"disable-archive"`

	// Validate json input against schema
	Validate bool `json:"validate"`

	// For LDAP Authentication and user synchronisation.
	LdapConfig *LdapConfig    `json:"ldap"`
	JwtConfig  *JWTAuthConfig `json:"jwts"`

	// If 0 or empty, the session/token does not expire!
	SessionMaxAge string `json:"session-max-age"`

	// If both those options are not empty, use HTTPS using those certificates.
	HttpsCertFile string `json:"https-cert-file"`
	HttpsKeyFile  string `json:"https-key-file"`

	// If not the empty string and `addr` does not end in ":80",
	// redirect every request incoming at port 80 to that url.
	RedirectHttpTo string `json:"redirect-http-to"`

	// If overwriten, at least all the options in the defaults below must
	// be provided! Most options here can be overwritten by the user.
	UiDefaults map[string]interface{} `json:"ui-defaults"`

	// Where to store MachineState files
	MachineStateDir string `json:"machine-state-dir"`

	// If not zero, automatically mark jobs as stopped running X seconds longer than their walltime.
	StopJobsExceedingWalltime int `json:"stop-jobs-exceeding-walltime"`

	// Array of Clusters
	Clusters []*ClusterConfig `json:"clusters"`
}
