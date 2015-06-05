# Rails CalDav Sample

## How To Run

Type in terminal:

```
git clone git@github.com:railsmuffin/rails-caldav-sample.git
cd rails-caldav-sample
bundle
bundle exec rake db:reset
bundle exec rails s
```

Then on your OS X devise
`System Preferences` -> `Internet Accounts` -> `+` -> `Add Other Account` -> `Add a CalDAV account`
and fill the fields:

<table>
  <tbody>
    <tr>
      <td><b>Account Type:</td>
      <td>Advanced</td>
    <tr>
    <tr>
      <td><b>User Name:</td>
      <td>caldav@example.com</td>
    <tr>
    <tr>
      <td><b>Password:</td>
      <td>password</td>
    <tr>
    <tr>
      <td><b>Server Address:</td>
      <td>localhost</td>
    <tr>
    <tr>
      <td><b>Server Path:</td>
      <td>/caldav/</td>
    <tr>
    <tr>
      <td><b>Port:</td>
      <td>3000</td>
    <tr>
    <tr>
      <td><b>Use SSL:</td>
      <td>no</td>
    <tr>
    <tr>
      <td><b>Use Kerberos:</td>
      <td>no</td>
    <tr>
  </tbody>
</table>

Run your Calendar application and CRUD events.
