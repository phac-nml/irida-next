import * as React from "react";

type DashboardProps = {
  name: string;
};

export default function Dashboard({ name }: DashboardProps) {
  return (
    <div>
      <h1>Dashboard</h1>
      <h2>{name}</h2>
    </div>
  );
}
