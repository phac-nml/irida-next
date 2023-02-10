import * as React from "react";

type DashboardProps = {
  name: string;
};

function foobar(): string {
  return "foobar";
}

export default function Dashboard({ name }: DashboardProps) {
  console.log(foobar());
  return (
    <div>
      <h1>Dashboard</h1>
      <h2>{name}</h2>
    </div>
  );
}
